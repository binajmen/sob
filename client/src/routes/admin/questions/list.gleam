import gleam/dynamic/decode
import gleam/http/response.{type Response}
import gleam/json
import gleam/list
import gleam/option.{None}
import gleam/string
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import modem
import plinth/browser/window
import router
import rsvp
import shared/question.{type Question}

pub type Model {
  Model(questions: List(Question))
}

pub fn init() -> #(Model, Effect(Msg)) {
  let model = Model(questions: [])
  #(model, fetch_questions(ApiReturnedQuestions))
}

pub type Msg {
  UserClickedDelete(String)
  UserConfirmedDelete(String)
  ApiReturnedQuestions(Result(List(Question), rsvp.Error))
  ApiDeletedQuestion(Result(Response(String), rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserClickedDelete(question_id) -> #(model, confirm_delete(question_id))
    UserConfirmedDelete(question_id) -> #(
      model,
      delete_question(question_id, ApiDeletedQuestion),
    )
    ApiReturnedQuestions(Ok(questions)) -> #(
      Model(..model, questions:),
      effect.none(),
    )
    ApiReturnedQuestions(Error(error)) -> {
      echo error
      #(model, effect.none())
    }
    ApiDeletedQuestion(Ok(_res)) -> {
      #(
        model,
        modem.push(router.to_path(router.AdminQuestionsList), None, None),
      )
    }
    ApiDeletedQuestion(Error(_)) -> #(model, effect.none())
  }
}

pub fn view(questions: List(Question)) -> Element(Msg) {
  html.div([attribute.class("space-y-4")], [
    html.div([attribute.class("prose flex justify-between items-start")], [
      html.h1([], [html.text("Questions")]),
      html.a([router.href(router.AdminQuestionsCreate)], [
        html.button([attribute.class("btn btn-primary")], [
          html.text("Create question"),
        ]),
      ]),
    ]),
    html.table([attribute.class("table table-zebra w-full")], [
      html.thead([], [
        html.tr([], [
          html.th([], [html.text("Prompt")]),
          html.th([], []),
        ]),
      ]),
      html.tbody(
        [],
        list.map(questions, fn(question) {
          html.tr([], [
            html.td([attribute.class("whitespace-pre-wrap")], [
              html.text(question.prompt |> string.slice(0, 200) <> "..."),
            ]),
            html.td([attribute.class("flex gap-2")], [
              html.a(
                [
                  router.href(router.AdminQuestionsView(question.id)),
                ],
                [
                  html.button([attribute.class("btn btn-primary btn-sm")], [
                    html.text("Edit"),
                  ]),
                ],
              ),
              html.button(
                [
                  attribute.class("btn btn-error btn-sm"),
                  event.on_click(UserClickedDelete(question.id)),
                ],
                [
                  html.text("Delete"),
                ],
              ),
            ]),
          ])
        }),
      ),
    ]),
  ])
}

fn fetch_questions(
  on_response handle_response: fn(Result(List(Question), rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "/api/questions"
  let decoder = decode.list(question.question_decoder())
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}

fn confirm_delete(question_id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    case window.confirm("Are you sure you want to delete this question?") {
      True -> dispatch(UserConfirmedDelete(question_id))
      False -> Nil
    }
  })
}

fn delete_question(
  id: String,
  on_response handle_response: fn(Result(Response(String), rsvp.Error)) -> Msg,
) -> Effect(Msg) {
  let url = "/api/questions/" <> id
  let body = json.null()
  let handler = rsvp.expect_ok_response(handle_response)
  rsvp.delete(url, body, handler)
}
