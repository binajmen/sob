import auth/router as auth
import cors_builder
import gleam/bytes_tree
import gleam/erlang/application
import gleam/http.{Delete, Get, Patch, Post, Put}
import gleam/http/response
import gleam/option.{None}
import lustre/attribute
import lustre/element
import lustre/element/html
import mist
import question/router as question
import server/context.{type Context}
import session/router as session
import vote/router as vote
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- cors_builder.wisp_middleware(req, cors())
  use req <- middleware(req, ctx)

  case req.method, wisp.path_segments(req) {
    method, ["api", ..rest] ->
      case method, rest {
        // auth
        Get, ["auth", "me"] -> auth.me(req, ctx)
        Post, ["auth", "sign-in"] -> auth.sign_in(req, ctx)
        Post, ["auth", "sign-up"] -> auth.sign_up(req, ctx)
        Post, ["auth", "guest"] -> auth.guest(req, ctx)
        // sessions
        Get, ["sessions"] -> session.list_sessions(req, ctx)
        Get, ["sessions", id] -> session.find_session(req, ctx, id)
        // users
        Get, ["users"] -> auth.list_users(req, ctx)
        // questions
        Get, ["questions"] -> question.list_questions(req, ctx)
        Post, ["questions"] -> question.create_question(req, ctx)
        Get, ["questions", "current"] ->
          question.find_current_question(req, ctx)
        Get, ["questions", "next"] -> question.find_next_question(req, ctx)
        Get, ["questions", id] -> question.find_question(req, ctx, id)
        Get, ["questions", id, "waiting-users"] ->
          question.list_users_without_votes(req, ctx, id)
        Patch, ["questions", id] -> question.update_question(req, ctx, id)
        Delete, ["questions", id] -> question.delete_question(req, ctx, id)
        // results
        Get, ["results", id] -> question.find_result(req, ctx, id)
        // votes
        Post, ["votes"] -> vote.create_vote(req, ctx)
        Get, ["votes", id] -> vote.find_vote(req, ctx, id)
        Delete, ["votes"] -> vote.delete_all_votes(req, ctx)
        // poll state
        Patch, ["poll-state"] -> question.update_poll_state(req, ctx)
        //
        _, _ -> wisp.not_found()
      }
    Get, _ -> serve_index()
    _, _ -> wisp.not_found()
  }
}

fn serve_index() -> Response {
  let html =
    html.html(
      [
        attribute.lang("en"),
        attribute.attribute("data-theme", "light"),
        attribute.attribute("style", "height: 100%"),
      ],
      [
        html.head([], [
          html.meta([attribute.attribute("charset", "UTF-8")]),
          html.meta([
            attribute.attribute(
              "content",
              "width=device-width, initial-scale=1.0",
            ),
            attribute.name("viewport"),
          ]),
          html.title([], "vote!"),
          html.link([
            attribute.type_("text/css"),
            attribute.rel("stylesheet"),
            attribute.href("https://cdn.jsdelivr.net/npm/daisyui@5"),
          ]),
          html.link([
            attribute.type_("text/css"),
            attribute.rel("stylesheet"),
            attribute.href(
              "https://cdn.jsdelivr.net/npm/charts.css/dist/charts.min.css",
            ),
          ]),
          html.link([
            attribute.type_("text/css"),
            attribute.rel("stylesheet"),
            attribute.href("/static/daisy.css"),
          ]),
          html.link([
            attribute.type_("text/css"),
            attribute.rel("stylesheet"),
            attribute.href("/static/client.css"),
          ]),
          html.script(
            [
              attribute.type_("module"),
              attribute.src("/static/client.mjs"),
            ],
            "",
          ),
          html.link([
            attribute.type_("text/css"),
            attribute.rel("stylesheet"),
            attribute.href("/static/client.min.css"),
          ]),
          // FIXME:
          // html.script(
          //   [
          //     attribute.type_("module"),
          //     attribute.src("/static/client.min.mjs"),
          //   ],
          //   "",
          // ),
          html.script(
            [attribute.type_("module"), attribute.src("/lustre/runtime.mjs")],
            "",
          ),
        ]),
        html.body(
          [
            attribute.class("prose p-4"),
            attribute.attribute("style", "height: 100%"),
          ],
          [
            html.div(
              [
                attribute.attribute("style", "height: 100%"),
                attribute.id("app"),
              ],
              [],
            ),
          ],
        ),
      ],
    )

  html
  |> element.to_document_string_tree
  |> wisp.html_response(200)
}

pub fn middleware(
  req: wisp.Request,
  ctx: Context,
  handle_request: fn(Request) -> Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.serve_static(req, under: "/static", from: ctx.static_directory)

  handle_request(req)
}

fn cors() {
  cors_builder.new()
  |> cors_builder.allow_origin("*")
  |> cors_builder.allow_credentials()
  |> cors_builder.allow_method(Get)
  |> cors_builder.allow_method(Post)
  |> cors_builder.allow_method(Put)
  |> cors_builder.allow_method(Patch)
  |> cors_builder.allow_method(Delete)
  |> cors_builder.allow_header("content-type")
}
