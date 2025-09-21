import auth/sql
import gleam/bit_array
import gleam/crypto
import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleam/option.{Some}
import gleam/result.{try}
import helpers
import pog
import server/context.{type Context}
import wisp.{type Request, type Response}
import youid/uuid

pub fn me(req: Request, ctx: Context) {
  use session_id <- helpers.require_session(req)
  use user <- helpers.require_user(session_id, ctx)
  json.object([
    #("id", json.string(user.id)),
    #("email", json.nullable(user.email, json.string)),
    #("first_name", json.nullable(user.first_name, json.string)),
    #("last_name", json.nullable(user.last_name, json.string)),
    #("is_admin", json.bool(user.is_admin)),
  ])
  |> json.to_string_tree
  |> wisp.json_response(200)
}

type SignInPayload {
  SignInPayload(email: String, password: String)
}

pub fn sign_in(req: Request, ctx: Context) {
  use json <- wisp.require_json(req)

  let result = {
    use payload <- try(decode_sign_in_payload(json))
    wisp.log_debug("Payload: " <> payload.email)
    use user <- try(authenticate_user(ctx, payload))
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
        60 * 60 * 24,
      )
    Error(error) -> error |> helpers.to_wisp_response
  }
}

fn decode_sign_in_payload(
  json: dynamic.Dynamic,
) -> Result(SignInPayload, helpers.ApiError) {
  decode.run(json, sign_in_payload_decoder())
  |> result.map_error(helpers.WrongFormat)
}

fn sign_in_payload_decoder() -> decode.Decoder(SignInPayload) {
  use email <- decode.field("email", decode.string)
  use password <- decode.field("password", decode.string)
  decode.success(SignInPayload(email:, password:))
}

fn authenticate_user(
  ctx: Context,
  payload: SignInPayload,
) -> Result(sql.FindUserByEmailRow, helpers.ApiError) {
  use user <- try(case sql.find_user_by_email(ctx.db, payload.email) {
    Ok(pog.Returned(1, [user])) -> Ok(user)
    Ok(_) -> Error(helpers.CustomError("Invalid credentials"))
    Error(error) -> Error(helpers.DatabaseError(error))
  })

  // FIXME:
  let assert Some(password_hash) = user.password_hash
  let assert Ok(password_hash) = bit_array.base64_decode(password_hash)
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

type SignUpPayload {
  SignUpPayload(
    email: String,
    password: String,
    first_name: String,
    last_name: String,
  )
}

pub fn sign_up(req: Request, ctx: Context) {
  use json <- wisp.require_json(req)

  let result = {
    use payload <- try(decode_sign_up_payload(json))
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

fn decode_sign_up_payload(
  json: dynamic.Dynamic,
) -> Result(SignUpPayload, helpers.ApiError) {
  decode.run(json, sign_up_payload_decoder())
  |> result.map_error(helpers.WrongFormat)
}

fn sign_up_payload_decoder() -> decode.Decoder(SignUpPayload) {
  use email <- decode.field("email", decode.string)
  use password <- decode.field("password", decode.string)
  use first_name <- decode.field("first_name", decode.string)
  use last_name <- decode.field("last_name", decode.string)
  decode.success(SignUpPayload(email:, password:, first_name:, last_name:))
}

fn create_user(
  ctx: Context,
  payload: SignUpPayload,
) -> Result(sql.CreateUserRow, helpers.ApiError) {
  let password_hash =
    crypto.hash(crypto.Sha256, bit_array.from_string(payload.password))
    |> bit_array.base64_encode(False)

  case
    sql.create_user(
      ctx.db,
      payload.email,
      password_hash,
      payload.first_name,
      payload.last_name,
    )
  {
    Ok(pog.Returned(1, [user])) -> Ok(user)
    Ok(_) -> Error(helpers.UnknownError)
    Error(error) -> Error(helpers.DatabaseError(error))
  }
}

type GuestPayload {
  GuestPayload(first_name: String, last_name: String)
}

pub fn guest(req: Request, ctx: Context) {
  use json <- wisp.require_json(req)

  let result = {
    use payload <- try(decode_guest_payload(json))
    use user <- try(create_guest(ctx, payload))
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

fn decode_guest_payload(
  json: dynamic.Dynamic,
) -> Result(GuestPayload, helpers.ApiError) {
  decode.run(json, guest_payload_decoder())
  |> result.map_error(helpers.WrongFormat)
}

fn guest_payload_decoder() -> decode.Decoder(GuestPayload) {
  use first_name <- decode.field("first_name", decode.string)
  use last_name <- decode.field("last_name", decode.string)
  decode.success(GuestPayload(first_name:, last_name:))
}

fn create_guest(
  ctx: Context,
  payload: GuestPayload,
) -> Result(sql.CreateGuestRow, helpers.ApiError) {
  case sql.create_guest(ctx.db, payload.first_name, payload.last_name) {
    Ok(pog.Returned(1, [user])) -> Ok(user)
    Ok(_) -> Error(helpers.UnknownError)
    Error(error) -> Error(helpers.DatabaseError(error))
  }
}

pub fn list_users(req: Request, ctx: Context) -> Response {
  use _ <- helpers.require_admin(req, ctx)

  let result = {
    use pog.Returned(_count, rows) <- try(sql.list_users(ctx.db))
    Ok(
      json.array(rows, fn(user) {
        json.object([
          #("id", json.string(uuid.to_string(user.id))),
          #("email", json.nullable(user.email, json.string)),
          #("first_name", json.nullable(user.first_name, json.string)),
          #("last_name", json.nullable(user.last_name, json.string)),
          #("is_admin", json.bool(user.is_admin)),
        ])
      }),
    )
  }

  case result {
    Error(_) -> wisp.internal_server_error()
    Ok(result) -> result |> json.to_string_tree |> wisp.json_response(200)
  }
}
