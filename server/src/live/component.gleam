import gleam/dynamic/decode
import gleam/int
import gleam/option.{type Option, None, Some}
import lustre.{type App}
import lustre/attribute
import lustre/component
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre/server_component
import question/sql
import rsvp
import shared/question

pub fn component() -> App(_, Model, Msg) {
  lustre.component(init, update, view, [])
}

pub type Status {
  Waiting
  Question(question.Question)
  Result(id: String)
  Finished
}

pub type Model {
  Model(
    status: Status,
    // question: Option(question.Question),
    // result: Option(question.Result),
    count: Int,
    connected_users: Int,
  )
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(
    Model(
      status: Waiting,
      // question: None,
      // result: None,
      count: 0,
      connected_users: 0,
    ),
    effect.none(),
  )
}

pub type Msg {
  AdminPressedNextQuestion
  ApiReturnedQuestion(Result(question.Question, rsvp.Error))
  AdminPressedCloseVoting
  UserClickedIncrement
  UserClickedDecrement
  UserConnected
  UserDisconnected
}

fn find_next_question(
  on_response handle_response: fn(Result(question.Question, rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "http://localhost:8000/api/questions/next"
  let decoder = question.question_decoder()
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    AdminPressedNextQuestion -> {
      #(model, find_next_question(ApiReturnedQuestion))
    }

    ApiReturnedQuestion(Ok(question)) -> {
      echo question
      #(Model(..model, status: Question(question)), effect.none())
    }
    ApiReturnedQuestion(Error(error)) -> {
      echo error
      echo "reached end of questions"
      #(model, effect.none())
    }

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
  html.div([], [
    html.h1([], [html.text("Poll")]),
    case model.status {
      Waiting -> view_waiting(model)
      Question(question) -> view_question(model, question)
      Result(id:) -> view_results(model, id)
      Finished -> view_finished(model)
    },
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

fn view_question(model: Model, question: question.Question) -> Element(Msg) {
  html.div([attribute.class("prose")], [
    html.h2([], [html.text(question.prompt)]),
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
  ])
}
