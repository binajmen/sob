import gleam/dynamic/decode
import gleam/json
import gleam/result.{try}
import pog
import server/context.{type Context}
import session/sql
import wisp.{type Request, type Response}
import youid/uuid

pub type Session {
  Session(id: String, user_id: String)
}

pub fn session_decoder() -> decode.Decoder(Session) {
  use id <- decode.field("id", decode.string)
  use user_id <- decode.field("user_id", decode.string)
  decode.success(Session(id:, user_id:))
}

pub fn list_sessions(_req: Request, ctx: Context) -> Response {
  let result = {
    use pog.Returned(_count, rows) <- try(sql.list_sessions(ctx.db))
    Ok(
      json.array(rows, fn(session) {
        json.object([#("id", json.string(uuid.to_string(session.id)))])
      }),
    )
  }

  case result {
    Error(_) -> wisp.internal_server_error()
    Ok(result) -> result |> json.to_string_tree |> wisp.json_response(200)
  }
}

pub fn find_session(_req: Request, ctx: Context, id: String) -> Response {
  let result = {
    use uuid <- try(uuid.from_string(id))
    case sql.find_session(ctx.db, uuid) {
      Ok(pog.Returned(1, [row])) ->
        Ok(json.object([#("id", json.string(uuid.to_string(row.id)))]))
      _ -> Error(Nil)
    }
  }

  case result {
    Error(_) -> wisp.internal_server_error()
    Ok(result) -> result |> json.to_string_tree |> wisp.json_response(200)
  }
}
// pub fn update_session(req: Request, ctx: Context, id: String) {
//   use json <- wisp.require_json(req)
//   let assert Ok(uuid) = uuid.from_string(id)

//   case decode.run(json, session_decoder()) {
//     Ok(session) -> {
//       let result = sql.update_session(ctx.db, uuid, session.user_id)
//       case result {
//         Ok(_) -> wisp.ok()
//         Error(error) -> {
//           echo error
//           helpers.pog_error_to_json(error) |> wisp.json_response(404)
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
