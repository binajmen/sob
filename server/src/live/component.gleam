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
  Question(question: question.Question)
  Result(result: question.Result)
  Finished
}

pub type Model {
  Model(status: Status)
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Model(status: Waiting), effect.none())
}

pub type Msg {
  AdminPressedWaiting
  AdminPressedNextQuestion
  AdminPressedCloseVoting
  AdminPressedFinished
  ApiReturnedQuestion(Result(question.Question, rsvp.Error))
  ApiReturnedResult(Result(question.Result, rsvp.Error))
}

fn find_next_question(
  on_response handle_response: fn(Result(question.Question, rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "http://localhost:8000/api/questions/next"
  let decoder = question.question_decoder()
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}

fn find_result(
  id: String,
  on_response handle_response: fn(Result(question.Result, rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "http://localhost:8000/api/results/" <> id
  let decoder = question.result_decoder()
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    AdminPressedWaiting -> #(Model(status: Waiting), effect.none())

    AdminPressedNextQuestion -> #(
      model,
      find_next_question(ApiReturnedQuestion),
    )

    AdminPressedCloseVoting -> {
      case model.status {
        Question(question) -> #(
          model,
          find_result(question.id, ApiReturnedResult),
        )
        _ -> #(model, effect.none())
      }
    }

    AdminPressedFinished -> #(Model(status: Finished), effect.none())

    ApiReturnedQuestion(Ok(question)) -> #(
      Model(status: Question(question)),
      effect.none(),
    )
    ApiReturnedQuestion(Error(error)) -> {
      echo error
      #(model, effect.none())
    }

    ApiReturnedResult(Ok(result)) -> #(
      Model(status: Result(result)) |> echo,
      effect.none(),
    )
    ApiReturnedResult(Error(error)) -> {
      echo error
      #(model, effect.none())
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    component.default_slot(
      [
        event.on("click", {
          use id <- decode.subfield(["target", "id"], decode.string)

          case id {
            "waiting" -> decode.success(AdminPressedWaiting)
            "next-question" -> decode.success(AdminPressedNextQuestion)
            "close-voting" -> decode.success(AdminPressedCloseVoting)
            "finished" -> decode.success(AdminPressedFinished)
            _ -> decode.failure(AdminPressedCloseVoting, "")
          }
        })
        |> server_component.include(["target.id"]),
      ],
      [],
    ),
    case model.status {
      Waiting -> view_waiting(model)
      Question(question) -> view_question(model, question)
      Result(result) -> view_results(model, result)
      Finished -> view_finished(model)
    },
  ])
}

fn view_waiting(model: Model) -> Element(Msg) {
  html.div([], [
    html.h2([], [html.text("Waiting to start the poll")]),
  ])
}

fn view_question(model: Model, question: question.Question) -> Element(Msg) {
  html.div([], [
    html.h2([], [
      html.text("Question #" <> int.to_string(question.position + 1)),
    ]),
    html.h3([], [html.text(question.prompt)]),
  ])
}

fn view_results(model: Model, result: question.Result) -> Element(Msg) {
  html.div([], [
    html.h2([], [html.text("Results")]),
    html.pre([], [html.text(int.to_string(result.yes_count))]),
  ])
}

fn view_finished(model: Model) -> Element(Msg) {
  html.div([], [
    html.h1([], [html.text("Finished")]),
  ])
}
