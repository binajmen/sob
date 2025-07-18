import envoy
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/io
import gleam/option.{Some}
import gleam/otp/actor
import gleam/otp/static_supervisor as supervisor
import mist.{type Connection, type ResponseData}
import pog
import server/context.{Context}
import server/counter
import server/router
import wisp
import wisp/wisp_mist

pub fn start(_type, _args) -> Result(process.Pid, actor.StartError) {
  io.println("starting supervisor..")

  let assert Ok(host) = envoy.get("PGHOST")
  let assert Ok(database) = envoy.get("PGDATABASE")
  let assert Ok(user) = envoy.get("PGUSER")
  let assert Ok(password) = envoy.get("PGPASSWORD")

  let db_name = process.new_name("db")
  let db = pog.named_connection(db_name)
  let database_pool =
    pog.default_config(db_name)
    |> pog.host(host)
    |> pog.database(database)
    |> pog.user(user)
    |> pog.password(Some(password))
    |> pog.pool_size(15)
    |> pog.supervised

  let assert Ok(priv_directory) = wisp.priv_directory("server")
  let static_directory = priv_directory <> "/static"

  let context = Context(db:, static_directory:)

  let secret_key_base = wisp.random_string(64)
  let http_server =
    fn(request: Request(Connection)) -> Response(ResponseData) {
      case request.path_segments(request) {
        ["ws"] -> counter.serve(request)
        _ ->
          {
            router.handle_request(_, context)
            |> wisp_mist.handler(secret_key_base)
          }(request)
      }
    }
    |> mist.new
    |> mist.port(8000)
    |> mist.supervised

  let supervisor =
    supervisor.new(supervisor.OneForOne)
    |> supervisor.add(database_pool)
    |> supervisor.add(http_server)
    |> supervisor.start

  case supervisor {
    Error(error) -> Error(error)
    Ok(supervisor) -> Ok(supervisor.pid)
  }
}

pub fn stop(_state) {
  io.println("stopping supervisor..")
}
