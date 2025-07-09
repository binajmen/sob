import server/context.{type Context}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  // use req <- web.middleware(req)
  echo ctx
  echo req.method
  wisp.ok()
  // case wisp.path_segments(req) {
  //   // This matches `/`.
  //   [] -> home_page(req)
  //
  //   // This matches `/comments`.
  //   ["comments"] -> comments(req)
  //
  //   // This matches `/comments/:id`.
  //   // The `id` segment is bound to a variable and passed to the handler.
  //   ["comments", id] -> show_comment(req, id)
  //
  //   // This matches all other paths.
  //   _ -> wisp.not_found()
  // }
}
