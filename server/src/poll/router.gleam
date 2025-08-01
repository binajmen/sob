import auth/router
import gleam/dynamic/decode
import gleam/json
import gleam/result.{try}
import helpers
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

type CreatePollPayload {
  CreatePollPayload(name: String)
}

fn create_poll_payload_decoder() -> decode.Decoder(CreatePollPayload) {
  use name <- decode.field("name", decode.string)
  decode.success(CreatePollPayload(name:))
}

pub fn create_poll(req: Request, ctx: Context) {
  use _ <- router.require_admin(req, ctx)
  use json <- wisp.require_json(req)

  let result = {
    use payload <- try(helpers.decode_json(json, create_poll_payload_decoder()))
    use poll_id <- try(do_create_poll(ctx, payload))
    Ok(poll_id)
  }

  case result {
    Ok(_poll_id) -> wisp.ok()
    Error(error) -> error |> helpers.to_wisp_response
  }
}

fn do_create_poll(
  ctx: Context,
  payload: CreatePollPayload,
) -> Result(uuid.Uuid, helpers.ApiError) {
  case sql.create_poll(ctx.db, payload.name) {
    Ok(pog.Returned(1, [session])) -> Ok(session.id)
    Ok(_) -> Error(helpers.UnknownError)
    Error(error) -> Error(helpers.DatabaseError(error))
  }
}
