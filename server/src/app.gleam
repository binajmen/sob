import app/router
import app/web.{Context}
import gleam/erlang/process
import mist
import sqlight
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  use db <- sqlight.with_connection(":memory:")
  let sql =
    "
    create table sessions (id text, name text);
    insert into sessions (id, name) values ('id', 'name');
    "
  let assert Ok(Nil) = sqlight.exec(sql, db)

  // A context is constructed holding the static directory path.
  let ctx = Context(static_dir: static_directory(), db:)
  // The handle_request function is partially applied with the context to make
  // the request handler function that only takes a request.
  let handler = router.handle_request(_, ctx)

  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}

pub fn static_directory() -> String {
  // The priv directory is where we store non-Gleam and non-Erlang files,
  // including static assets to be served.
  // This function returns an absolute path and works both in development and in
  // production after compilation.
  let assert Ok(priv_directory) = wisp.priv_directory("app")
  priv_directory <> "/static"
}
