import gleam/dynamic/decode
import gleam/json
import gleam/result.{try}
import pog
import poll/sql
import server/context.{type Context}
import wisp.{type Request, type Response}
import youid/uuid

pub type Poll {
  Poll(id: String, name: String)
}

pub fn poll_decoder() -> decode.Decoder(Poll) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  decode.success(Poll(id:, name:))
}

pub fn list_polls(_req: Request, ctx: Context) -> Response {
  let result = {
    use pog.Returned(_count, rows) <- try(sql.list_polls(ctx.db))
    Ok(
      json.array(rows, fn(poll) {
        json.object([
          #("id", json.string(uuid.to_string(poll.id))),
          #("name", json.string(poll.name)),
        ])
      }),
    )
  }

  case result {
    Error(_) -> wisp.internal_server_error()
    Ok(result) -> result |> json.to_string_tree |> wisp.json_response(200)
  }
}
