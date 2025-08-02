import auth/sql
import gleam/bit_array
import gleam/crypto
import gleam/dynamic
import gleam/dynamic/decode
import gleam/result.{try}
import helpers
import pog
import server/context.{type Context}
import shared/user
import wisp.{type Request, type Response}
import youid/uuid

type AuthPayload {
  AuthPayload(email: String, password: String)
}

fn auth_payload_decoder() -> decode.Decoder(AuthPayload) {
  use email <- decode.field("email", decode.string)
  use password <- decode.field("password", decode.string)
  decode.success(AuthPayload(email:, password:))
}

pub fn require_session(req: Request, next: fn(String) -> Response) -> Response {
  let session_id = wisp.get_cookie(req, "session_id", wisp.Signed)
  case session_id {
    Ok(session_id) -> next(session_id)
    Error(_) -> helpers.unauthorised()
  }
}

pub fn require_user(
  session_id: String,
  ctx: Context,
  next: fn(user.User) -> Response,
) -> Response {
  // TOFIX
  let assert Ok(session_id) = uuid.from_string(session_id)
  case sql.find_user_by_session(ctx.db, session_id) {
    Ok(pog.Returned(1, [user])) ->
      next(user.User(
        id: uuid.to_string(user.id),
        email: user.email,
        is_admin: user.is_admin,
      ))
    Ok(_) -> helpers.unauthorised()
    Error(error) ->
      helpers.DatabaseError(error)
      |> helpers.to_wisp_response
  }
}

pub fn require_admin(
  req: Request,
  ctx: Context,
  next: fn(user.User) -> Response,
) -> Response {
  use session_id <- require_session(req)
  use user <- require_user(session_id, ctx)
  case user.is_admin {
    True -> next(user)
    False -> helpers.unauthorised()
  }
}

pub fn me(req: Request, ctx: Context) {
  use session_id <- require_session(req)
  use _user <- require_user(session_id, ctx)
  wisp.ok()
}

pub fn sign_in(req: Request, ctx: Context) {
  use json <- wisp.require_json(req)

  let result = {
    use payload <- try(decode_payload(json))
    use user <- try(authenticate_user(ctx, payload))
    use session_id <- try(create_session(ctx, user.id))
    Ok(session_id)
  }

  case result {
    Ok(session_id) ->
      wisp.ok()
      |> helpers.set_cookie(
        req,
        "session_id",
        uuid.to_string(session_id),
        wisp.Signed,
        60 * 60 * 24,
      )
    Error(error) -> error |> helpers.to_wisp_response
  }
}

pub fn sign_up(req: Request, ctx: Context) {
  use json <- wisp.require_json(req)

  let result = {
    use payload <- try(decode_payload(json))
    use user <- try(create_user(ctx, payload))
    use session_id <- try(create_session(ctx, user.id))
    Ok(session_id)
  }

  case result {
    Ok(session_id) ->
      wisp.ok()
      |> wisp.set_cookie(
        req,
        "session_id",
        uuid.to_string(session_id),
        wisp.Signed,
        60 * 60,
      )
    Error(error) -> error |> helpers.to_wisp_response
  }
}

fn decode_payload(
  json: dynamic.Dynamic,
) -> Result(AuthPayload, helpers.ApiError) {
  decode.run(json, auth_payload_decoder())
  |> result.map_error(helpers.WrongFormat)
}

fn authenticate_user(
  ctx: Context,
  payload: AuthPayload,
) -> Result(sql.FindUserByEmailRow, helpers.ApiError) {
  use user <- try(case sql.find_user_by_email(ctx.db, payload.email) {
    Ok(pog.Returned(1, [user])) -> Ok(user)
    Ok(_) -> Error(helpers.CustomError("Invalid credentials"))
    Error(error) -> Error(helpers.DatabaseError(error))
  })

  // FIXME:
  let assert Ok(password_hash) = bit_array.base64_decode(user.password_hash)
  let challenge =
    crypto.hash(crypto.Sha256, bit_array.from_string(payload.password))
  case crypto.secure_compare(password_hash, challenge) {
    True -> Ok(user)
    False -> Error(helpers.CustomError("Invalid credentials"))
  }
}

fn create_session(
  ctx: Context,
  user_id: uuid.Uuid,
) -> Result(uuid.Uuid, helpers.ApiError) {
  case sql.create_session(ctx.db, user_id) {
    Ok(pog.Returned(1, [session])) -> Ok(session.id)
    Ok(_) -> Error(helpers.UnknownError)
    Error(error) -> Error(helpers.DatabaseError(error))
  }
}

fn create_user(
  ctx: Context,
  payload: AuthPayload,
) -> Result(sql.CreateUserRow, helpers.ApiError) {
  let password_hash =
    crypto.hash(crypto.Sha256, bit_array.from_string(payload.password))
    |> bit_array.base64_encode(False)

  case sql.create_user(ctx.db, payload.email, password_hash) {
    Ok(pog.Returned(1, [user])) -> Ok(user)
    Ok(_) -> Error(helpers.UnknownError)
    Error(error) -> Error(helpers.DatabaseError(error))
  }
}
