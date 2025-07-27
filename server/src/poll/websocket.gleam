import gleam/erlang/process.{type Selector, type Subject}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/option.{type Option, Some}
import lustre
import lustre/server_component
import mist.{type Connection, type ResponseData}
import poll/component

pub fn serve(
  request: Request(Connection),
  component: lustre.Runtime(component.Msg),
  _id: String,
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
    component: lustre.Runtime(component.Msg),
    self: Subject(server_component.ClientMessage(component.Msg)),
  )
}

type PollSocketMessage =
  server_component.ClientMessage(component.Msg)

type PollSocketInit =
  #(PollSocket, Option(Selector(PollSocketMessage)))

fn init_poll_socket(
  _,
  component: lustre.Runtime(component.Msg),
) -> PollSocketInit {
  // The server component runtime communicates to the websocket process using
  // Gleam's standard process messaging. We construct a new subject that the
  // runtime can send messages to, and then we initialise a selector so that we
  // can handle those messages in `loop_poll_socket`.
  let self = process.new_subject()
  let selector =
    process.new_selector()
    |> process.select(self)

  // Calling `register_subject` is how the runtime knows to send messages to
  // this process when it wants to communicate with the client. In Lustre, server
  // components are not opinionated about the transport layer or your network
  // setup: instead the runtime broadcasts messages to any registered subjects
  // and lets you handle the transport layer yourself.
  server_component.register_subject(self)
  |> lustre.send(to: component)

  #(PollSocket(component:, self:), Some(selector))
}

fn loop_poll_socket(
  state: PollSocket,
  message: mist.WebsocketMessage(PollSocketMessage),
  connection: mist.WebsocketConnection,
) -> mist.Next(PollSocket, PollSocketMessage) {
  case message {
    // The client runtime will send us JSON-encoded text frames that we need to
    // decode and pass to the server component runtime.
    mist.Text(json) -> {
      case json.parse(json, server_component.runtime_message_decoder()) {
        Ok(runtime_message) -> lustre.send(state.component, runtime_message)
        // This case will only be hit if something other than Lustre's client
        // runtime sends us a message.
        Error(_) -> Nil
      }

      mist.continue(state)
    }

    mist.Binary(_) -> {
      mist.continue(state)
    }

    // We hit this case when the server component runtime sends us a message that
    // we need to forward to the client. Because Lustre does not control your
    // network connection, it's our app's responsibility to make sure these messages
    // are encoded and sent to the client.
    mist.Custom(client_message) -> {
      let json = server_component.client_message_to_json(client_message)
      let assert Ok(_) = mist.send_text_frame(connection, json.to_string(json))

      mist.continue(state)
    }

    mist.Closed | mist.Shutdown -> {
      // The server component runtime sets up a process monitor that can clean
      // up if our socket process dies or is killed, but it's good practice to
      // clean up ourselves if we get the opportunity.
      server_component.deregister_subject(state.self)
      |> lustre.send(to: state.component)

      mist.stop()
    }
  }
}

fn close_poll_socket(state: PollSocket) -> Nil {
  server_component.deregister_subject(state.self)
  |> lustre.send(to: state.component)
}
