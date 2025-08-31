import gleam/dynamic/decode
import gleam/list
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
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

pub fn view(questions: List(Question)) -> Element(Msg) {
  html.div([], [
    html.h1([], [html.text("Admin Questions")]),
    html.ul(
      [],
      list.map(questions, fn(question) {
        html.li([], [html.text(question.poll_id <> " - " <> question.prompt)])
      }),
    ),
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
