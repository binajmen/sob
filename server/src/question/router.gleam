import gleam/dynamic/decode
import gleam/json
import gleam/result.{try}
import helpers
import pog
import question/sql
import server/context.{type Context}
import wisp.{type Request, type Response}
import youid/uuid

pub fn list_questions_by_poll(
  req: Request,
  ctx: Context,
  id: String,
) -> Response {
  use _ <- helpers.require_admin(req, ctx)

  let result = {
    let assert Ok(uuid) = uuid.from_string(id)
    use pog.Returned(_count, rows) <- try(sql.list_questions_by_poll(
      ctx.db,
      uuid,
    ))
    Ok(
      json.array(rows, fn(question) {
        json.object([
          #("id", json.string(uuid.to_string(question.id))),
          #("poll_id", json.string(uuid.to_string(question.poll_id))),
          #("prompt", json.string(question.prompt)),
        ])
      }),
    )
  }

  case result {
    Error(_) -> wisp.internal_server_error()
    Ok(result) -> result |> json.to_string_tree |> wisp.json_response(200)
  }
}

pub fn find_question(req: Request, ctx: Context, id: String) -> Response {
  use _ <- helpers.require_session(req)

  let result = {
    use uuid <- try(uuid.from_string(id))
    case sql.find_question(ctx.db, uuid) {
      Ok(pog.Returned(1, [question])) ->
        Ok(
          json.object([
            #("id", json.string(uuid.to_string(question.id))),
            #("poll_id", json.string(uuid.to_string(question.poll_id))),
            #("prompt", json.string(question.prompt)),
          ]),
        )
      _ -> Error(Nil)
    }
  }

  case result {
    Error(_) -> wisp.internal_server_error()
    Ok(result) -> result |> json.to_string_tree |> wisp.json_response(200)
  }
}

type CreateQuestionPayload {
  CreateQuestionPayload(poll_id: String, prompt: String)
}

pub fn create_question(req: Request, ctx: Context) {
  use _ <- helpers.require_admin(req, ctx)
  use json <- wisp.require_json(req)

  let result = {
    use payload <- try(helpers.decode_json(
      json,
      create_question_payload_decoder(),
    ))
    let assert Ok(poll_id) = uuid.from_string(payload.poll_id)
    use question_id <- try(do_create_question(ctx, poll_id, payload))
    Ok(question_id)
  }

  case result {
    Ok(_question_id) -> wisp.ok()
    Error(error) -> error |> helpers.to_wisp_response
  }
}

fn create_question_payload_decoder() -> decode.Decoder(CreateQuestionPayload) {
  use poll_id <- decode.field("poll_id", decode.string)
  use prompt <- decode.field("prompt", decode.string)
  decode.success(CreateQuestionPayload(poll_id:, prompt:))
}

fn do_create_question(
  ctx: Context,
  poll_id: uuid.Uuid,
  payload: CreateQuestionPayload,
) -> Result(uuid.Uuid, helpers.ApiError) {
  case sql.create_question(ctx.db, poll_id, payload.prompt) {
    Ok(pog.Returned(1, [question])) -> Ok(question.id)
    Ok(_) -> Error(helpers.UnknownError)
    Error(error) -> Error(helpers.DatabaseError(error))
  }
}

type UpdateQuestionPayload {
  UpdateQuestionPayload(prompt: String)
}

pub fn update_question(req: Request, ctx: Context, id: String) {
  use _ <- helpers.require_admin(req, ctx)
  use json <- wisp.require_json(req)
  let assert Ok(uuid) = uuid.from_string(id)

  let result = {
    use payload <- try(helpers.decode_json(
      json,
      update_question_payload_decoder(),
    ))
    let result = sql.update_question(ctx.db, uuid, payload.prompt)
    case result {
      Ok(pog.Returned(1, [question])) ->
        Ok(
          json.object([
            #("id", json.string(uuid.to_string(question.id))),
            #("poll_id", json.string(uuid.to_string(question.poll_id))),
            #("prompt", json.string(question.prompt)),
          ]),
        )
      Ok(_) -> Error(helpers.UnknownError)
      Error(error) -> Error(helpers.DatabaseError(error))
    }
  }

  case result {
    Error(error) -> error |> helpers.to_wisp_response
    Ok(result) -> result |> json.to_string_tree |> wisp.json_response(200)
  }
}

fn update_question_payload_decoder() -> decode.Decoder(UpdateQuestionPayload) {
  use prompt <- decode.field("prompt", decode.string)
  decode.success(UpdateQuestionPayload(prompt:))
}
