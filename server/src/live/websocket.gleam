import gleam/erlang/process.{type Selector, type Subject}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/option.{type Option, Some}
import live/component as live_component
import lustre
import lustre/server_component
import mist.{type Connection, type ResponseData}

pub fn serve(
  request: Request(Connection),
  component: lustre.Runtime(live_component.Msg),
) -> Response(ResponseData) {
  mist.websocket(
    request:,
    on_init: init_poll_socket(_, component),
    handler: loop_poll_socket,
    on_close: close_poll_socket,
  )
}

type PollSocket {
  PollSocket(
    component: lustre.Runtime(live_component.Msg),
    self: Subject(server_component.ClientMessage(live_component.Msg)),
  )
}

type PollSocketMessage =
  server_component.ClientMessage(live_component.Msg)

type PollSocketInit =
  #(PollSocket, Option(Selector(PollSocketMessage)))

fn init_poll_socket(
  _,
  component: lustre.Runtime(live_component.Msg),
) -> PollSocketInit {
  let self = process.new_subject()
  let selector =
    process.new_selector()
    |> process.select(self)

  server_component.register_subject(self)
  |> lustre.send(to: component)

  lustre.send(component, lustre.dispatch(live_component.UserConnected))

  #(PollSocket(component:, self:), Some(selector))
}

fn loop_poll_socket(
  state: PollSocket,
  message: mist.WebsocketMessage(PollSocketMessage),
  connection: mist.WebsocketConnection,
) -> mist.Next(PollSocket, PollSocketMessage) {
  case message {
    mist.Text(json) -> {
      case json.parse(json, server_component.runtime_message_decoder()) {
        Ok(runtime_message) -> lustre.send(state.component, runtime_message)
        Error(_) -> Nil
      }

      mist.continue(state)
    }

    mist.Binary(_) -> {
      mist.continue(state)
    }

    mist.Custom(client_message) -> {
      let json = server_component.client_message_to_json(client_message)
      let assert Ok(_) = mist.send_text_frame(connection, json.to_string(json))

      mist.continue(state)
    }

    mist.Closed | mist.Shutdown -> {
      server_component.deregister_subject(state.self)
      |> lustre.send(to: state.component)

      lustre.send(
        state.component,
        lustre.dispatch(live_component.UserDisconnected),
      )

      mist.stop()
    }
  }
}

fn close_poll_socket(state: PollSocket) -> Nil {
  server_component.deregister_subject(state.self)
  |> lustre.send(to: state.component)

  lustre.send(state.component, lustre.dispatch(live_component.UserDisconnected))
}
