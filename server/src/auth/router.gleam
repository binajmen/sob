import auth/sql
import gleam/bit_array
import gleam/crypto
import gleam/dynamic
import gleam/dynamic/decode
import gleam/result.{map_error, try}
import gleam/string_tree
import helpers
import pog
import server/context.{type Context}
import wisp.{type Request}
import youid/uuid

type AuthError {
  WrongPayloadFormat(errors: List(decode.DecodeError))
  InvalidCredentials
  DatabaseError(error: pog.QueryError)
  InternalServerError
}

type AuthPayload {
  AuthPayload(email: String, password: String)
}

fn auth_payload_decoder() -> decode.Decoder(AuthPayload) {
  use email <- decode.field("email", decode.string)
  use password <- decode.field("password", decode.string)
  decode.success(AuthPayload(email:, password:))
}

// pub fn sign_in(req: Request, ctx: Context) {
//   use json <- wisp.require_json(req)

//   case decode.run(json, auth_payload_decoder()) {
//     Ok(AuthPayload(email, password)) -> {
//       case authenticate_user(ctx, email, password) {
//         Ok(user) -> {
//           case sql.create_session(ctx.db, user.id) {
//             Ok(pog.Returned(1, [session])) ->
//               uuid.to_string(session.id)
//               |> string_tree.from_string
//               |> wisp.json_response(200)
//             Error(error) -> {
//               echo error
//               helpers.pog_error_to_json(error) |> wisp.json_response(500)
//             }
//             _ -> {
//               string_tree.from_string("Unexpected result from create_session")
//               |> wisp.json_response(500)
//             }
//           }
//         }
//         Error(error) -> {
//           string_tree.from_string(error)
//           |> wisp.json_response(401)
//         }
//       }
//     }
//     Error(errors) -> {
//       echo errors
//       helpers.decode_errors_to_json(errors)
//       |> wisp.json_response(404)
//     }
//   }
// }

pub fn sign_in(req: Request, ctx: Context) {
  use json <- wisp.require_json(req)

  case do_sign_in(ctx, json) {
    Ok(session_id) -> {
      session_id
      |> uuid.to_string
      |> string_tree.from_string
      |> wisp.json_response(200)
    }
    Error(WrongPayloadFormat(errors)) -> {
      helpers.decode_errors_to_json(errors)
      |> wisp.json_response(404)
    }
    Error(InvalidCredentials) -> {
      string_tree.from_string("Invalid credentials")
      |> wisp.json_response(401)
    }
    Error(DatabaseError(error)) -> {
      helpers.pog_error_to_json(error) |> wisp.json_response(500)
    }
    Error(InternalServerError) -> {
      string_tree.from_string("Internal server error")
      |> wisp.json_response(500)
    }
  }
}

fn do_sign_in(ctx: Context, json: dynamic.Dynamic) {
  use payload <- try(
    decode.run(json, auth_payload_decoder())
    |> result.map_error(WrongPayloadFormat),
  )
  use user <- try(authenticate_user(ctx, payload.email, payload.password))
  use session <- try(
    sql.create_session(ctx.db, user.id) |> map_error(DatabaseError),
  )
  case session {
    pog.Returned(1, [session]) -> Ok(session.id)
    _ -> Error(InternalServerError)
  }
}

pub fn sign_up(req: Request, ctx: Context) {
  use json <- wisp.require_json(req)

  case decode.run(json, auth_payload_decoder()) {
    Ok(AuthPayload(email, password)) -> {
      let password_hash =
        crypto.hash(crypto.Sha256, bit_array.from_string(password))
        |> bit_array.base64_encode(False)
      case sql.create_user(ctx.db, email, password_hash) {
        Ok(pog.Returned(1, [user])) ->
          uuid.to_string(user.id)
          |> string_tree.from_string
          |> wisp.json_response(200)
        Error(error) -> {
          echo error
          helpers.pog_error_to_json(error) |> wisp.json_response(500)
        }
        _ -> {
          string_tree.from_string("Unexpected result from create_session")
          |> wisp.json_response(500)
        }
      }
    }
    Error(errors) -> {
      echo errors
      helpers.decode_errors_to_json(errors)
      |> wisp.json_response(404)
    }
  }
}

fn authenticate_user(
  ctx: Context,
  email: String,
  password: String,
) -> Result(sql.FindUserByEmailRow, AuthError) {
  use user <- try(case sql.find_user_by_email(ctx.db, email) {
    Ok(pog.Returned(1, [user])) -> Ok(user)
    _ -> Error(InvalidCredentials)
  })

  let assert Ok(password_hash) = bit_array.base64_decode(user.password_hash)
  let challenge = crypto.hash(crypto.Sha256, bit_array.from_string(password))
  case crypto.secure_compare(password_hash, challenge) {
    False -> Error(InvalidCredentials)
    True -> Ok(user)
  }
}
