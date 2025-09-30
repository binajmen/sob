import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result.{try}
import helpers
import pog
import server/context.{type Context}
import shared/user
import shared/vote
import vote/sql
import wisp.{type Request, type Response}
import youid/uuid

pub fn find_vote(req: Request, ctx: Context, question_id: String) -> Response {
  use session_id <- helpers.require_session(req)
  use user <- helpers.require_user(session_id, ctx)

  let result = {
    use question_id <- try(uuid.from_string(question_id))
    use user_id <- try(uuid.from_string(user.id))
    case sql.find_vote(ctx.db, question_id, user_id) {
      Ok(pog.Returned(1, [vote])) ->
        Ok(
          json.object([
            #("id", json.string(uuid.to_string(vote.id))),
            #("question_id", json.string(uuid.to_string(vote.question_id))),
            #("user_id", json.string(uuid.to_string(vote.user_id))),
            #("vote", json.string(vote.vote)),
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

type CreateVotePayload {
  CreateVotePayload(question_id: String, vote: String)
}

pub fn create_vote(req: Request, ctx: Context) {
  use session_id <- helpers.require_session(req)
  use user <- helpers.require_user(session_id, ctx)
  use json <- wisp.require_json(req)

  let result = {
    use payload <- try(helpers.decode_json(json, create_vote_payload_decoder()))
    
    // Check for optional voting_for_user_id field
    let voting_for_user_id = case decode.run(json, decode.at(["voting_for_user_id"], decode.string)) {
      Ok(value) -> Some(value)
      Error(_) -> None
    }
    
    use vote <- try(do_create_vote(ctx, user, payload, voting_for_user_id))
    let vote =
      json.object([
        #("id", json.string(uuid.to_string(vote.id))),
        #("question_id", json.string(uuid.to_string(vote.question_id))),
        #("user_id", json.string(uuid.to_string(vote.user_id))),
        #("vote", json.string(vote.vote)),
      ])
    Ok(vote)
  }

  case result {
    Ok(vote) -> vote |> json.to_string_tree |> wisp.json_response(200)
    Error(error) -> error |> helpers.to_wisp_response
  }
}

fn create_vote_payload_decoder() -> decode.Decoder(CreateVotePayload) {
  use question_id <- decode.field("question_id", decode.string)
  use vote <- decode.field("vote", decode.string)
  decode.success(CreateVotePayload(question_id:, vote:))
}

fn do_create_vote(
  ctx: Context,
  user: user.User,
  payload: CreateVotePayload,
  voting_for_user_id: Option(String),
) -> Result(sql.CreateVoteRow, helpers.ApiError) {
  let question_id = uuid.from_string(payload.question_id)
  
  // Determine which user_id to use for the vote
  let target_user_id = case voting_for_user_id {
    Some(proxy_user_id) -> proxy_user_id
    None -> user.id
  }
  
  let user_id = uuid.from_string(target_user_id)

  case question_id, user_id {
    Ok(question_id), Ok(user_id) -> {
      case vote.vote_type_from_string(payload.vote) {
        Ok(_) -> {
          case sql.create_vote(ctx.db, question_id, user_id, payload.vote) {
            Ok(pog.Returned(1, [vote])) -> Ok(vote)
            Ok(_) -> Error(helpers.UnknownError)
            Error(error) -> Error(helpers.DatabaseError(error))
          }
        }
        Error(_) -> Error(helpers.CustomError("Invalid vote value"))
      }
    }
    _, _ -> Error(helpers.CustomError("Invalid UUID format"))
  }
}

pub fn delete_all_votes(req: Request, ctx: Context) -> Response {
  let result = {
    case sql.delete_all_votes(ctx.db) {
      Ok(pog.Returned(1, [_])) -> Ok(Nil)
      Ok(_) -> Ok(Nil)
      Error(error) -> Error(helpers.DatabaseError(error))
    }
  }

  case result {
    Error(error) -> error |> helpers.to_wisp_response
    Ok(_) -> wisp.ok()
  }
}
