import app/web.{type Context}
import gleam/dynamic/decode
import gleam/http.{Get, Post}
import gleam/io
import gleam/json
import gleam/result
import gleam/string_tree
import sqlight
import wisp.{type Request, type Response}

pub type Session {
  Session(id: String, name: String)
}

fn session_decoder() -> decode.Decoder(Session) {
  use id <- decode.field(0, decode.string)
  use name <- decode.field(1, decode.string)
  decode.success(Session(id:, name:))
}

fn session_decoder_payload() -> decode.Decoder(Session) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  decode.success(Session(id:, name:))
}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req, ctx)

  case wisp.path_segments(req) {
    [] -> home(req)
    ["sessions"] -> sessions(req, ctx)
    _ -> wisp.not_found()
  }
}

fn home(req: Request) -> Response {
  use <- wisp.require_method(req, Get)

  let body = string_tree.from_string("{\"foo\": \"Bar\"}")
  wisp.json_response(body, 200)
}

fn sessions(req: Request, ctx: Context) -> Response {
  case req.method {
    Get -> list_sessions(req, ctx)
    Post -> create_session(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

fn list_sessions(_req: Request, ctx: Context) -> Response {
  let sql = "select id, name from sessions;"
  let assert Ok(rows) =
    sqlight.query(sql, on: ctx.db, with: [], expecting: session_decoder())

  let result =
    json.array(from: rows, of: fn(session) {
      json.object([
        #("id", json.string(session.id)),
        #("name", json.string(session.name)),
      ])
    })

  wisp.json_response(json.to_string_tree(result), 200)
}

fn create_session(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)

  let assert Ok(payload) = {
    use session <- result.try(decode.run(json, session_decoder_payload()))
    Ok(session)
  }

  let sql = "insert into sessions (id, name) values ($1, $2);"
  let result =
    sqlight.query(
      sql,
      on: ctx.db,
      with: [sqlight.text(payload.id), sqlight.text(payload.name)],
      expecting: decode.success(Nil),
    )

  case result {
    Ok(_) -> wisp.response(200)
    Error(_) -> wisp.internal_server_error()
  }
}
