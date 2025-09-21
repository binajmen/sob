import auth/sql
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http/response
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import gleam/string_tree
import pog
import server/context.{type Context}
import shared/user
import wisp.{type Request, type Response}
import youid/uuid

pub fn uuid_decoder() {
  use bit_array <- decode.then(decode.bit_array)
  case uuid.from_bit_array(bit_array) {
    Ok(uuid) -> decode.success(uuid)
    Error(_) -> decode.failure(uuid.v7(), "Uuid")
  }
}

pub type ApiError {
  CustomError(reason: String)
  DatabaseError(error: pog.QueryError)
  UnknownError
  WrongFormat(errors: List(decode.DecodeError))
}

pub fn decode_json(
  json: dynamic.Dynamic,
  decoder: decode.Decoder(a),
) -> Result(a, ApiError) {
  decode.run(json, decoder)
  |> result.map_error(WrongFormat)
}

pub fn to_wisp_response(error: ApiError) {
  case error {
    CustomError(reason) -> {
      string_tree.from_string(reason)
      |> wisp.json_response(404)
    }
    DatabaseError(error) -> {
      pog_error_to_json(error)
      |> wisp.json_response(500)
    }
    UnknownError -> {
      string_tree.from_string("Unknown error")
      |> wisp.json_response(500)
    }
    WrongFormat(errors) -> {
      decode_errors_to_json(errors)
      |> wisp.json_response(404)
    }
  }
}

pub fn decode_errors_to_json(errors: List(decode.DecodeError)) {
  let errors =
    list.map(errors, fn(error) {
      case error {
        decode.DecodeError(expected, found, path) -> #(
          string.join(path, "."),
          json.object([
            #("expected", json.string(expected)),
            #("found", json.string(found)),
          ]),
        )
      }
    })

  json.object([
    #("error", json.string("wrong_format")),
    #("details", json.object(errors)),
  ])
  |> json.to_string_tree()
}

pub fn pog_error_to_json(error: pog.QueryError) {
  case error {
    pog.ConstraintViolated(message, constraint, detail) ->
      json.object([
        #("error", json.string("constraint_violated")),
        #(
          "detail",
          json.object([
            #("message", json.string(message)),
            #("constraint", json.string(constraint)),
            #("detail", json.string(detail)),
          ]),
        ),
      ])
    _ -> json.string("Undocumented error")
    // pog.ConnectionUnavailable -> todo
    // pog.PostgresqlError(_, _, _) -> todo
    // pog.QueryTimeout -> todo
    // pog.UnexpectedArgumentCount(_, _) -> todo
    // pog.UnexpectedArgumentType(_, _) -> todo
    // pog.UnexpectedResultType(_) -> todo
  }
  |> json.to_string_tree()
}

pub fn unauthorised() -> wisp.Response {
  response.Response(401, [], wisp.Empty)
}

pub fn require_session(req: Request, next: fn(String) -> Response) -> Response {
  let session_id = wisp.get_cookie(req, "session_id", wisp.Signed)
  case session_id {
    Ok(session_id) -> next(session_id)
    Error(_) -> unauthorised()
    // Error(_) -> wisp.redirect("/sign-in")
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
        first_name: user.first_name,
        last_name: user.last_name,
        is_admin: user.is_admin,
      ))
    Ok(_) -> unauthorised()
    Error(error) ->
      DatabaseError(error)
      |> to_wisp_response
  }
}

pub fn require_admin(
  req: Request,
  ctx: Context,
  next: fn(user.User) -> Response,
) -> Response {
  use session_id <- require_session(req)
  use user <- require_user(session_id, ctx)
  echo user
  case user.is_admin {
    True -> next(user)
    False -> unauthorised()
  }
}
