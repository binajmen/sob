import gleam/dynamic/decode
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
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
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    QuestionIdChanged(id) -> #(
      Model(..model, question_id: Some(id)),
      effect.none(),
    )

    ApiReturnedCurrentQuestion(Ok(Some(question_id))) -> #(
      Model(..model, question_id: Some(question_id)),
      fetch_waiting_users(question_id, ApiReturnedUsers),
    )
    ApiReturnedCurrentQuestion(Ok(None)) -> #(model, effect.none())
    ApiReturnedCurrentQuestion(Error(_)) -> #(model, effect.none())

    ApiReturnedUsers(Ok(users)) -> #(
      Model(..model, users: Some(users)),
      effect.none(),
    )
    ApiReturnedUsers(Error(_)) -> #(model, effect.none())
  }
}

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
        ],
        [view_controls()],
      ),
      view_users(model.question_id),
    ],
  )
}

fn view_users(question_id: Option(String)) -> Element(Msg) {
  let question_id_attr = case question_id {
    None -> attribute.none()
    Some(id) -> attribute.data("question", id)
  }

  html.div(
    [
      attribute.id("users"),
      attribute.class("mt-4"),
      question_id_attr,
    ],
    [],
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
