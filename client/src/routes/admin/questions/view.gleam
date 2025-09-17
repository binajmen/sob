import components/textarea
import formal/form.{type Form}
import gleam/json
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import rsvp
import shared/question.{type Question}

pub type Model {
  Model(question: Option(Question), form: Form(UpdateQuestionData))
}

pub type UpdateQuestionData {
  UpdateQuestionData(id: String, prompt: String)
}

fn form() -> Form(UpdateQuestionData) {
  form.new({
    use id <- form.field("id", form.parse_string)
    use prompt <- form.field("prompt", form.parse_string)
    form.success(UpdateQuestionData(id:, prompt:))
  })
}

pub fn init(id: String) -> #(Model, Effect(Msg)) {
  let model = Model(question: None, form: form())
  #(model, fetch_question(id, ApiReturnedQuestion))
}

pub type Msg {
  UserSubmittedForm(Result(UpdateQuestionData, Form(UpdateQuestionData)))
  ApiQuestionUpdated(Result(Question, rsvp.Error))
  ApiReturnedQuestion(Result(Question, rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserSubmittedForm(result) ->
      case result {
        Ok(values) -> #(model, update_question(values, ApiQuestionUpdated))
        Error(form) -> #(Model(..model, form:), effect.none())
      }
    ApiQuestionUpdated(Ok(question)) -> #(
      Model(..model, question: Some(question)),
      effect.none(),
    )
    ApiQuestionUpdated(Error(_)) -> #(model, effect.none())
    ApiReturnedQuestion(Ok(question)) -> #(
      Model(..model, question: Some(question)),
      effect.none(),
    )
    ApiReturnedQuestion(Error(_)) -> #(model, effect.none())
  }
}

pub fn view(
  question: Option(Question),
  form: Form(UpdateQuestionData),
) -> Element(Msg) {
  let submit = fn(fields) {
    form
    |> form.add_values(fields)
    |> form.run
    |> UserSubmittedForm
  }

  case question {
    None -> html.text("loading..")
    Some(question) ->
      html.div([attribute.class("space-y-4")], [
        html.div([attribute.class("prose flex justify-between items-start")], [
          html.h1([], [html.text("Update question")]),
        ]),
        html.form([event.on_submit(submit), attribute.class("space-y-2")], [
          html.input([
            attribute.type_("hidden"),
            attribute.name("id"),
            attribute.value(question.id),
          ]),
          textarea.view(form, "prompt", "Question", Some(question.prompt)),
          html.button(
            [attribute.type_("submit"), attribute.class("btn btn-primary")],
            [html.text("Update question")],
          ),
        ]),
      ])
  }
}

fn fetch_question(
  id: String,
  on_response handle_response: fn(Result(Question, rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "/api/questions/" <> id
  let decoder = question.question_decoder()
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}

fn update_question(
  question: UpdateQuestionData,
  on_response handle_response: fn(Result(Question, rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "/api/questions/" <> question.id
  let body =
    json.object([
      #("prompt", json.string(question.prompt)),
    ])
  let handler = rsvp.expect_json(question.question_decoder(), handle_response)

  rsvp.patch(url, body, handler)
}
