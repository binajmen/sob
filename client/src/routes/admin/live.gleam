import gleam/dynamic/decode
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre/server_component
import rsvp
import shared/user

pub type Model {
  Model(question_id: Option(String), users: Option(List(user.User)))
}

pub fn init() -> #(Model, Effect(Msg)) {
  let model = Model(question_id: None, users: None)
  #(model, fetch_current_question(ApiReturnedCurrentQuestion))
}

pub type Msg {
  QuestionIdChanged(String)
  ApiReturnedCurrentQuestion(Result(Option(String), rsvp.Error))
  ApiReturnedUsers(Result(List(user.User), rsvp.Error))
  RefreshUsers
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    QuestionIdChanged(id) -> #(
      Model(..model, question_id: Some(id)),
      effect.batch([
        fetch_waiting_users(id, ApiReturnedUsers),
        start_refresh_timer(),
      ]),
    )

    ApiReturnedCurrentQuestion(Ok(Some(question_id))) -> #(
      Model(..model, question_id: Some(question_id)),
      effect.batch([
        fetch_waiting_users(question_id, ApiReturnedUsers),
        start_refresh_timer(),
      ]),
    )
    ApiReturnedCurrentQuestion(Ok(None)) -> #(
      Model(..model, question_id: None, users: None),
      effect.none(),
    )
    ApiReturnedCurrentQuestion(Error(_)) -> #(model, effect.none())

    ApiReturnedUsers(Ok(users)) -> #(
      Model(..model, users: Some(users)),
      effect.none(),
    )
    ApiReturnedUsers(Error(_)) -> #(model, effect.none())

    RefreshUsers -> {
      case model.question_id {
        Some(question_id) -> #(
          model,
          effect.batch([
            fetch_waiting_users(question_id, ApiReturnedUsers),
            start_refresh_timer(),
          ]),
        )
        None -> #(model, effect.none())
      }
    }
  }
}

fn start_refresh_timer() -> Effect(Msg) {
  use dispatch <- effect.from
  do_set_timeout(1000, fn() { dispatch(RefreshUsers) })
}

@external(javascript, "./live_ffi.mjs", "setTimeout")
fn do_set_timeout(ms: Int, callback: fn() -> Nil) -> Nil

fn fetch_waiting_users(
  question_id: String,
  on_response handle_response: fn(Result(List(user.User), rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "/api/questions/" <> question_id <> "/waiting-users"
  let decoder = decode.list(user.user_decoder())
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}

pub fn view(model: Model) -> Element(Msg) {
  html.div(
    [
      attribute.class("prose"),
    ],
    [
      html.h1([attribute.class("text-center !m-0")], [
        html.text("Sing Out Brussels!"),
      ]),
      html.h2([attribute.class("text-center !m-0")], [
        html.text("The Fabulous Queer Choir"),
      ]),
      server_component.element(
        [
          server_component.route("/ws/live"),
          server_component.method(server_component.WebSocket),
          event.on("next-question", {
            decode.at(["detail"], decode.string)
            |> decode.map(QuestionIdChanged)
          }),
        ],
        [view_controls()],
      ),
      view_users(model),
    ],
  )
}

fn view_users(model: Model) -> Element(Msg) {
  let question_id_attr = case model.question_id {
    None -> attribute.none()
    Some(id) -> attribute.data("question", id)
  }

  html.div(
    [
      attribute.id("users"),
      attribute.class("mt-4"),
      question_id_attr,
    ],
    [
      html.h3([attribute.class("text-lg font-semibold mb-2")], [
        html.text("Waiting for votes:"),
      ]),
      case model.users {
        None ->
          html.div([attribute.class("text-gray-500")], [html.text("Loading...")])
        Some([]) ->
          html.div([attribute.class("text-gray-500")], [
            html.text("All users have voted!"),
          ])
        Some(users) ->
          html.ul(
            [attribute.class("space-y-1")],
            users
              |> list.map(fn(user) {
                let name = case user.first_name, user.last_name {
                  Some(first), Some(last) -> first <> " " <> last
                  Some(first), None -> first
                  None, Some(last) -> last
                  None, None ->
                    case user.email {
                      Some(email) -> email
                      None -> "Unknown user"
                    }
                }
                html.li([attribute.class("text-sm")], [html.text("• " <> name)])
              }),
          )
      },
    ],
  )
}

fn view_controls() -> Element(msg) {
  html.div([attribute.class("space-x-4")], [
    html.button(
      [attribute.id("waiting"), attribute.class("btn btn-primary btn-sm")],
      [
        html.text("⏱️ Waiting"),
      ],
    ),
    html.button(
      [attribute.id("next-question"), attribute.class("btn btn-primary btn-sm")],
      [
        html.text("❓ Next question"),
      ],
    ),
    html.button(
      [
        attribute.id("close-voting"),
        attribute.class("btn btn-primary btn-sm"),
      ],
      [html.text("🛑 Close voting")],
    ),
    html.button(
      [attribute.id("finished"), attribute.class("btn btn-primary btn-sm")],
      [
        html.text("🎬 End"),
      ],
    ),
    html.button(
      [
        attribute.id("reset-votes"),
        attribute.class("btn btn-primary btn-sm"),
      ],
      [html.text("🧹 Reset")],
    ),
  ])
}

fn fetch_current_question(
  on_response handle_response: fn(Result(Option(String), rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "/api/questions/current"
  let decoder = decode.optional(decode.at(["id"], decode.string))
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}
