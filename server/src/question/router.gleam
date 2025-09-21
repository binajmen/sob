import gleam/dynamic/decode
import gleam/json
import gleam/option
import gleam/result.{try}
import helpers
import pog
import question/sql
import server/context.{type Context}
import wisp.{type Request, type Response}
import youid/uuid

pub fn list_questions(req: Request, ctx: Context) -> Response {
  use _ <- helpers.require_admin(req, ctx)

  let result = {
    use pog.Returned(_count, rows) <- try(sql.list_questions(ctx.db))
    Ok(
      json.array(rows, fn(question) {
        json.object([
          #("id", json.string(uuid.to_string(question.id))),
          #("prompt", json.string(question.prompt)),
          #("position", json.int(question.position)),
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
            #("prompt", json.string(question.prompt)),
            #("position", json.int(question.position)),
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

pub fn find_current_question(_req: Request, ctx: Context) -> Response {
  wisp.log_debug("Finding current question")
  // use _ <- helpers.require_session(req)

  let result = {
    case sql.find_current_question(ctx.db) {
      Ok(pog.Returned(1, [question])) ->
        Ok(
          json.object([
            #("id", json.string(uuid.to_string(question.id))),
            #("prompt", json.string(question.prompt)),
            #("position", json.int(question.position)),
          ]),
        )
      Ok(pog.Returned(0, [])) -> Ok(json.null())
      _ -> Error(Nil)
    }
  }

  case result {
    Error(_) -> wisp.internal_server_error()
    Ok(result) -> result |> json.to_string_tree |> wisp.json_response(200)
  }
}

pub fn find_next_question(_req: Request, ctx: Context) -> Response {
  wisp.log_debug("Finding next question")
  // use _ <- helpers.require_session(req)

  let result = {
    case sql.find_next_question(ctx.db) {
      Ok(pog.Returned(1, [question])) ->
        Ok(
          json.object([
            #("id", json.string(uuid.to_string(question.id))),
            #("prompt", json.string(question.prompt)),
            #("position", json.int(question.position)),
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

pub fn find_result(_req: Request, ctx: Context, id: String) -> Response {
  wisp.log_debug("Finding result")
  // use _ <- helpers.require_session(req)

  let result = {
    let assert Ok(uuid) = uuid.from_string(id)
    case sql.find_result(ctx.db, uuid) {
      Ok(pog.Returned(1, [result])) ->
        Ok(
          json.object([
            #("id", json.string(uuid.to_string(result.id))),
            #("prompt", json.string(result.prompt)),
            #("yes_count", json.int(result.yes_count)),
            #("no_count", json.int(result.no_count)),
            #("blank_count", json.int(result.blank_count)),
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
  CreateQuestionPayload(prompt: String)
}

pub fn create_question(req: Request, ctx: Context) {
  use _ <- helpers.require_admin(req, ctx)
  use json <- wisp.require_json(req)

  let result = {
    use payload <- try(helpers.decode_json(
      json,
      create_question_payload_decoder(),
    ))
    use question_id <- try(do_create_question(ctx, payload))
    Ok(question_id) |> echo
  }

  case result {
    Ok(_question_id) -> wisp.ok()
    Error(error) -> error |> helpers.to_wisp_response
  }
}

fn create_question_payload_decoder() -> decode.Decoder(CreateQuestionPayload) {
  use prompt <- decode.field("prompt", decode.string)
  decode.success(CreateQuestionPayload(prompt:))
}

fn do_create_question(
  ctx: Context,
  payload: CreateQuestionPayload,
) -> Result(uuid.Uuid, helpers.ApiError) {
  case sql.create_question(ctx.db, payload.prompt) {
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
            #("prompt", json.string(question.prompt)),
            #("position", json.int(question.position)),
          ]),
        )
        |> echo
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

pub fn delete_question(req: Request, ctx: Context, id: String) -> Response {
  use _ <- helpers.require_admin(req, ctx)
  let assert Ok(uuid) = uuid.from_string(id)

  case sql.delete_question(ctx.db, uuid) {
    Ok(pog.Returned(1, _)) -> wisp.ok()
    Ok(_) -> wisp.not_found()
    Error(error) -> helpers.DatabaseError(error) |> helpers.to_wisp_response
  }
}

pub fn list_users_without_votes(
  req: Request,
  ctx: Context,
  id: String,
) -> Response {
  // use _ <- helpers.require_admin(req, ctx)

  let result = {
    use uuid <- try(uuid.from_string(id))
    case sql.list_users_without_votes(ctx.db, uuid) {
      Ok(pog.Returned(_count, rows)) ->
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
      Error(_) -> Error(Nil)
    }
  }

  case result {
    Error(_) -> wisp.internal_server_error()
    Ok(result) -> result |> json.to_string_tree |> wisp.json_response(200)
  }
}

type UpdatePollStatePayload {
  UpdatePollStatePayload(
    current_question_id: option.Option(String),
    status: String,
  )
}

pub fn update_poll_state(req: Request, ctx: Context) -> Response {
  // use _ <- helpers.require_admin(req, ctx)
  use json <- wisp.require_json(req)

  let result = {
    use payload <- try(helpers.decode_json(
      json,
      update_poll_state_payload_decoder(),
    ))
    use question_uuid <- try(case payload.current_question_id {
      option.Some(id) ->
        case uuid.from_string(id) {
          Ok(uuid) -> Ok(option.Some(uuid))
          Error(_) -> Error(helpers.CustomError("Invalid question ID format"))
        }
      option.None -> Ok(option.None)
    })
    do_update_poll_state(ctx, question_uuid, payload.status)
  }

  case result {
    Ok(_) -> wisp.ok()
    Error(error) -> error |> helpers.to_wisp_response
  }
}

fn update_poll_state_payload_decoder() -> decode.Decoder(UpdatePollStatePayload) {
  use current_question_id <- decode.field(
    "current_question_id",
    decode.optional(decode.string),
  )
  use status <- decode.field("status", decode.string)
  decode.success(UpdatePollStatePayload(current_question_id:, status:))
}

fn do_update_poll_state(
  ctx: Context,
  current_question_id: option.Option(uuid.Uuid),
  status: String,
) -> Result(Nil, helpers.ApiError) {
  let result = case current_question_id {
    option.Some(question_id) ->
      sql.update_poll_state_with_question(ctx.db, question_id, status)
    option.None -> sql.update_poll_state_no_question(ctx.db, status)
  }

  case result {
    Ok(pog.Returned(1, _)) -> Ok(Nil)
    Ok(_) -> Error(helpers.UnknownError)
    Error(error) -> Error(helpers.DatabaseError(error))
  }
}
