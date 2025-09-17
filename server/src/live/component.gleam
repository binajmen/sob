import gleam/dynamic/decode
import gleam/int
import gleam/option.{type Option, None}
import lustre.{type App}
import lustre/attribute
import lustre/component
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre/server_component
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
  AdminPressedNextQuestion
  AdminPressedCloseVoting
  UserClickedIncrement
  UserClickedDecrement
  UserConnected
  UserDisconnected
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    AdminPressedNextQuestion -> #(
      Model(..model, status: Question(id: "q1")),
      effect.none(),
    )
    AdminPressedCloseVoting -> #(
      Model(..model, status: Result(id: "q1")),
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
  case model.status {
    Waiting -> view_waiting(model)
    Question(id:) -> view_question(model, id)
    Result(id:) -> view_results(model, id)
    Finished -> view_finished(model)
  }
}

fn view_finished(model: Model) -> Element(Msg) {
  html.div([], [
    html.h1([], [html.text("Finished")]),
  ])
}

fn view_results(model: Model, id: String) -> Element(Msg) {
  html.div([], [
    html.h1([], [html.text("Results")]),
  ])
}

fn view_question(model: Model, id: String) -> Element(Msg) {
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
        html.text("Connected users:  "),
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
    component.default_slot(
      [
        event.on("click", {
          use id <- decode.subfield(["target", "id"], decode.string)

          case id {
            "next-question" -> decode.success(AdminPressedNextQuestion)
            "close-voting" -> decode.success(AdminPressedCloseVoting)
            _ -> decode.failure(AdminPressedCloseVoting, "")
          }
        })
        |> server_component.include(["target.id"]),
      ],
      [],
    ),
  ])
}
