import gleam/erlang/process
import server/app

pub fn main() -> Nil {
  // app.start(0, 0)
  process.sleep_forever()
}
