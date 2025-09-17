import gleam/int
import gleam/option.{type Option, None, Some}
import lustre.{type App}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared/question

pub fn component() -> App(_, Model, Msg) {
  lustre.component(init, update, view, [])
}

pub type Status {
  Waiting
  Question(id: String)
  Result(id: String)
  Finished
}

pub type Model {
  Model(
    status: Status,
    question: Option(question.Question),
    result: Option(question.Result),
    count: Int,
    connected_users: Int,
  )
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(
    Model(
      status: Waiting,
      question: None,
      result: None,
      count: 0,
      connected_users: 0,
    ),
    effect.none(),
  )
}

pub type Msg {
  UserClickedStart
  UserClickedIncrement
  UserClickedDecrement
  UserConnected
  UserDisconnected
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserClickedStart -> #(
      Model(..model, status: Question(id: "q1")),
      effect.none(),
    )
    UserClickedIncrement -> #(
      Model(..model, count: model.count + 1),
      effect.none(),
    )
    UserClickedDecrement -> #(
      Model(..model, count: model.count - 1),
      effect.none(),
    )
    UserConnected -> #(
      Model(..model, connected_users: model.connected_users + 1),
      effect.none(),
    )
    UserDisconnected -> #(
      Model(..model, connected_users: model.connected_users - 1),
      effect.none(),
    )
  }
}

fn view(model: Model) -> Element(Msg) {
  // let count = int.to_string(model.count)
  // let connected_users = int.to_string(model.connected_users)

  case model.status {
    Waiting -> view_waiting(model)
    Question(id:) -> view_question(model)
    Result(id:) -> todo
    Finished -> todo
  }
}

fn view_question(model: Model) -> Element(Msg) {
  html.div([], [
    html.h1([], [html.text("Question")]),
  ])
}

fn view_waiting(model: Model) -> Element(Msg) {
  let count = int.to_string(model.count)
  let connected_users = int.to_string(model.connected_users)

  html.div([], [
    html.h1([], [html.text("Poll")]),
    html.div([attribute.class("mb-4")], [
      html.p([attribute.class("text-sm text-gray-500")], [
        html.text("Connected users: "),
        html.text(connected_users),
      ]),
    ]),
    html.div([attribute.class("flex justify-between")], [
      html.button(
        [
          attribute.class("btn btn-primary"),
          event.on_click(UserClickedDecrement),
        ],
        [
          html.text("-"),
        ],
      ),
      html.p([], [html.text("Count: "), html.text(count)]),
      html.button(
        [
          attribute.class("btn btn-primary"),
          event.on_click(UserClickedIncrement),
        ],
        [
          html.text("+"),
        ],
      ),
    ]),
    html.slot([attribute.data("test", count)], []),
  ])
}
