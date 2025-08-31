import gleam/dynamic/decode
import gleam/list
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import router
import rsvp
import shared/question.{type Question}

pub type Model {
  Model(questions: List(Question))
}

pub fn init(poll_id: String) -> #(Model, Effect(Msg)) {
  let model = Model(questions: [])
  #(model, fetch_questions(poll_id, ApiReturnedQuestions))
}

pub type Msg {
  ApiReturnedQuestions(Result(List(Question), rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ApiReturnedQuestions(Ok(questions)) ->
      #(Model(questions: questions), effect.none())
      |> echo
    ApiReturnedQuestions(Error(error)) -> {
      echo error
      #(model, effect.none())
    }
  }
}

pub fn view(poll_id: String, questions: List(Question)) -> Element(Msg) {
  html.div([], [
    html.div([attribute.class("prose flex justify-between items-start")], [
      html.h1([], [html.text("Questions")]),
      html.a([router.href(router.AdminPollsQuestionsCreate(poll_id))], [
        html.button([attribute.class("btn btn-primary")], [
          html.text("Create question"),
        ]),
      ]),
    ]),
    html.table([attribute.class("table table-zebra w-auto")], [
      html.thead([], [
        html.tr([], [
          html.th([], []),
          html.th([], [html.text("Name")]),
          html.th([], []),
        ]),
      ]),
      html.tbody(
        [],
        list.map(questions, fn(question) {
          html.tr([], [
            html.th([], [html.text(question.id)]),
            html.td([], [html.text(question.prompt)]),
            html.td([], [
              html.a([router.href(router.AdminPollsView(question.id))], [
                html.text("View"),
              ]),
            ]),
          ])
        }),
      ),
    ]),
  ])
}

fn fetch_questions(
  poll_id: String,
  on_response handle_response: fn(Result(List(Question), rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "http://localhost:3000/api/polls/" <> poll_id <> "/questions"
  let decoder =
    decode.list(question.question_decoder()) |> decode.map(list.take(_, 10))
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}
