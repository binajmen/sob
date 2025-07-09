import gleam/erlang/process
import gleam/io
import gleam/option.{Some}
import gleam/otp/actor
import gleam/otp/static_supervisor as supervisor
import mist
import pog
import server/context.{Context}
import server/router
import wisp
import wisp/wisp_mist

pub fn start(_type, _args) -> Result(process.Pid, actor.StartError) {
  io.println("starting supervisor..")

  let db_name = process.new_name("db")
  let db = pog.named_connection(db_name)
  let database_pool =
    pog.default_config(db_name)
    |> pog.host("localhost")
    |> pog.database("postgres")
    |> pog.user("postgres")
    |> pog.password(Some("postgres"))
    |> pog.pool_size(15)
    |> pog.supervised

  let context = Context(db:)

  let secret_key_base = wisp.random_string(64)
  let http_server =
    router.handle_request(_, context)
    |> wisp_mist.handler(secret_key_base)
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
