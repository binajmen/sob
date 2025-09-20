import envoy
import gleam/bytes_tree
import gleam/erlang/application
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/io
import gleam/option.{None, Some}
import gleam/otp/actor
import gleam/otp/static_supervisor as supervisor
import live/component as live
import live/websocket
import lustre
import lustre/attribute
import lustre/element
import lustre/element/html
import mist.{type Connection, type ResponseData}
import pog
import server/context.{Context}
import server/router
import wisp
import wisp/wisp_mist

pub fn start(_type, _args) -> Result(process.Pid, actor.StartError) {
  case do_start() {
    Error(error) -> Error(error)
    Ok(supervisor) -> Ok(supervisor.pid)
  }
}

pub fn do_start() {
  io.println("starting supervisor..")

  wisp.configure_logger()
  wisp.set_logger_level(wisp.DebugLevel)

  let assert Ok(host) = envoy.get("PGHOST")
  let assert Ok(database) = envoy.get("PGDATABASE")
  let assert Ok(user) = envoy.get("PGUSER")
  let assert Ok(password) = envoy.get("PGPASSWORD")
  let assert Ok(secret_key_base) = envoy.get("SECRET_KEY_BASE")

  let db_name = process.new_name("db")
  let db = pog.named_connection(db_name)
  let database_pool =
    pog.default_config(db_name)
    |> pog.user(user)
    |> pog.password(Some(password))
    |> pog.host(host)
    |> pog.database(database)
    |> pog.pool_size(15)
    |> pog.supervised

  io.println("database pool")

  let assert Ok(priv_directory) = wisp.priv_directory("server")
  let static_directory = priv_directory <> "/static"

  let context = Context(db:, static_directory:)

  let assert Ok(live_component) =
    lustre.start_server_component(live.component(), Nil)

  let http_server =
    fn(request: Request(Connection)) -> Response(ResponseData) {
      case request.path_segments(request) {
        ["ws", "live"] -> {
          websocket.serve(request, live_component)
        }
        ["lustre", "runtime.mjs"] -> serve_runtime()
        _ ->
          {
            router.handle_request(_, context)
            |> wisp_mist.handler(secret_key_base)
          }(request)
      }
    }
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(8000)
    |> mist.supervised

  io.println("http server")

  supervisor.new(supervisor.OneForOne)
  |> supervisor.add(database_pool)
  |> supervisor.add(http_server)
  |> supervisor.start
}

fn serve_runtime() -> Response(ResponseData) {
  let assert Ok(lustre_priv) = application.priv_directory("lustre")
  let file_path = lustre_priv <> "/static/lustre-server-component.mjs"

  case mist.send_file(file_path, offset: 0, limit: None) {
    Ok(file) ->
      response.new(200)
      |> response.prepend_header("content-type", "application/javascript")
      |> response.set_body(file)

    Error(_) ->
      response.new(404)
      |> response.set_body(mist.Bytes(bytes_tree.new()))
  }
}

pub fn stop(_state) {
  io.println("stopping supervisor..")
}
