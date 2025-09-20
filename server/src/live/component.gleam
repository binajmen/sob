import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/option
import lustre.{type App}
import lustre/attribute
import lustre/component
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre/server_component
import rsvp
import shared/question
import wisp
import youid/uuid

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
  NoOp
  AdminPressedWaiting
  AdminPressedNextQuestion
  AdminPressedCloseVoting
  AdminPressedFinished
  ApiReturnedQuestion(Result(question.Question, rsvp.Error))
  ApiReturnedResult(Result(question.Result, rsvp.Error))
  ApiUpdatedPollState(Result(Nil, rsvp.Error))
}

fn find_next_question(
  on_response handle_response: fn(Result(question.Question, rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "/api/questions/next"
  let decoder = question.question_decoder()
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}

fn find_result(
  id: String,
  on_response handle_response: fn(Result(question.Result, rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "/api/results/" <> id
  let decoder = question.result_decoder()
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}

fn update_poll_state(
  current_question_id: option.Option(String),
  status: String,
  on_response handle_response: fn(Result(Nil, rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "/api/poll-state"
  let body =
    json.object([
      #("current_question_id", case current_question_id {
        option.Some(id) -> json.string(id)
        option.None -> json.null()
      }),
      #("status", json.string(status)),
    ])
  let decoder = decode.success(Nil)
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.patch(url, body, handler)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NoOp -> #(model, effect.none())

    AdminPressedWaiting -> #(
      Model(status: Waiting),
      update_poll_state(option.None, "waiting", ApiUpdatedPollState),
    )

    AdminPressedNextQuestion -> #(
      model,
      find_next_question(ApiReturnedQuestion),
    )

    AdminPressedCloseVoting -> {
      case model.status {
        Question(question) -> #(
          model,
          effect.batch([
            find_result(question.id, ApiReturnedResult),
            event.emit("no-questions", json.string(question.id)),
          ]),
        )
        _ -> #(model, effect.none())
      }
    }

    AdminPressedFinished -> #(
      Model(status: Finished),
      update_poll_state(option.None, "finished", ApiUpdatedPollState),
    )

    ApiReturnedQuestion(Ok(question)) -> #(
      Model(status: Question(question)),
      effect.batch([
        event.emit("next-question", json.string(question.id)),
        update_poll_state(
          option.Some(question.id),
          "voting",
          ApiUpdatedPollState,
        ),
      ]),
    )
    ApiReturnedQuestion(Error(error)) -> {
      echo error
      #(model, effect.none())
    }

    ApiReturnedResult(Ok(result)) -> #(
      Model(status: Result(result)),
      update_poll_state(option.Some(result.id), "results", ApiUpdatedPollState),
    )
    ApiReturnedResult(Error(error)) -> {
      echo error
      #(model, effect.none())
    }

    ApiUpdatedPollState(Ok(_)) -> #(model, effect.none())
    ApiUpdatedPollState(Error(error)) -> {
      echo error
      #(model, effect.none())
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    case model.status {
      Waiting -> view_waiting()
      Question(question) -> view_question(question)
      Result(result) -> view_results(result)
      Finished -> view_finished()
    },
    component.default_slot(
      [
        event.on("click", {
          use id <- decode.subfield(["target", "id"], decode.string)

          case id {
            "waiting" -> decode.success(AdminPressedWaiting)
            "next-question" -> decode.success(AdminPressedNextQuestion)
            "close-voting" -> decode.success(AdminPressedCloseVoting)
            "finished" -> decode.success(AdminPressedFinished)
            _ -> decode.failure(NoOp, "")
          }
        })
        |> server_component.include(["target.id"]),
      ],
      [],
    ),
  ])
}

fn view_waiting() -> Element(Msg) {
  html.div([attribute.id("view-waiting")], [
    html.h2([], [html.text("Waiting to start the poll")]),
  ])
}

fn view_question(question: question.Question) -> Element(Msg) {
  html.div([attribute.id("view-questions")], [
    html.h2([], [
      html.text("Question #" <> int.to_string(question.position)),
    ]),
    html.h3([], [html.text(question.prompt)]),
  ])
}

fn view_results(result: question.Result) -> Element(Msg) {
  html.div([attribute.id("view-results")], [
    html.h2([], [html.text("Results")]),
    html.pre([], [html.text(int.to_string(result.yes_count))]),
    html.pre([], [html.text(int.to_string(result.no_count))]),
    html.pre([], [html.text(int.to_string(result.blank_count))]),
  ])
}

fn view_finished() -> Element(Msg) {
  html.div([attribute.id("view-finished")], [
    html.h1([], [html.text("Finished")]),
  ])
}
