import gleam/dict.{type Dict}
import gleam/erlang/process.{type Name, type Subject}
import gleam/otp/actor
import gleam/otp/supervision
import lustre
import poll/component as poll_component

pub type Poll =
  lustre.Runtime(poll_component.Msg)

pub type Message {
  GetPoll(reply_to: Subject(Result(Poll, Nil)), id: String)
}

pub fn start(name: Name(Message)) {
  dict.new()
  |> actor.new()
  |> actor.named(name)
  |> actor.on_message(handle_message)
  |> actor.start()
}

pub fn supervised(name: Name(Message)) {
  supervision.supervisor(fn() { start(name) })
}

pub fn get_poll(subject: Subject(Message), id: String) {
  actor.call(subject, 1000, GetPoll(_, id))
}

fn handle_message(state: Dict(String, Poll), message: Message) {
  case message {
    GetPoll(reply_to:, id:) -> {
      case dict.get(state, id) {
        Error(_) -> {
          let poll = poll_component.component()
          let assert Ok(component) = lustre.start_server_component(poll, Nil)
          process.send(reply_to, Ok(component))
          actor.continue(dict.insert(state, id, component))
        }
        Ok(component) -> {
          process.send(reply_to, Ok(component))
          actor.continue(state)
        }
      }
    }
  }
}
