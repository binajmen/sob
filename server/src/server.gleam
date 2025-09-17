import gleam/erlang/process
import server/app

pub fn main() -> Nil {
  let assert Ok(_supervisor) = app.do_start()
  process.sleep_forever()
}
