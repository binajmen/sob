import components/breadcrumbs
import components/textarea
import formal/form.{type Form}

import gleam/json
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import modem
import router
import rsvp
import shared/poll.{type Poll}
import shared/question.{type Question}

pub type Model {
  Model(
    poll: Option(Poll),
    question: Option(Question),
    form: Form(UpdateQuestionData),
  )
}

pub type UpdateQuestionData {
  UpdateQuestionData(id: String, poll_id: String, prompt: String)
}

fn form() -> Form(UpdateQuestionData) {
  form.new({
    use id <- form.field("id", form.parse_string)
    use poll_id <- form.field("poll_id", form.parse_string)
    use prompt <- form.field("prompt", form.parse_string)
    form.success(UpdateQuestionData(id:, poll_id:, prompt:))
  })
}

pub fn init(poll_id: String, id: String) -> #(Model, Effect(Msg)) {
  let model = Model(poll: None, question: None, form: form())
  #(
    model,
    effect.batch([
      fetch_poll(poll_id, ApiReturnedPoll),
      fetch_question(id, ApiReturnedQuestion),
    ]),
  )
}

pub type Msg {
  UserSubmittedForm(Result(UpdateQuestionData, Form(UpdateQuestionData)))
  ApiQuestionUpdated(Result(Question, rsvp.Error))
  ApiReturnedPoll(Result(Poll, rsvp.Error))
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
    ApiReturnedPoll(Ok(poll)) -> #(
      Model(..model, poll: Some(poll)),
      effect.none(),
    )
    ApiReturnedPoll(Error(_)) -> #(model, effect.none())
    ApiReturnedQuestion(Ok(question)) -> #(
      Model(..model, question: Some(question)),
      effect.none(),
    )
    ApiReturnedQuestion(Error(_)) -> #(model, effect.none())
  }
}

pub fn view(
  poll: Option(Poll),
  question: Option(Question),
  form: Form(UpdateQuestionData),
) -> Element(Msg) {
  let submit = fn(fields) {
    form
    |> form.add_values(fields)
    |> form.run
    |> UserSubmittedForm
  }

  case poll, question {
    Some(poll), Some(question) ->
      html.div([attribute.class("space-y-4")], [
        breadcrumbs.view([
          breadcrumbs.Crumb("Admin", Some(router.to_path(router.Admin))),
          breadcrumbs.Crumb("Polls", Some(router.to_path(router.AdminPolls))),
          breadcrumbs.Crumb(
            poll.name,
            Some(router.to_path(router.AdminPollsView(poll.id))),
          ),
          breadcrumbs.Crumb(
            "Questions",
            Some(router.to_path(router.AdminQuestions(poll.id))),
          ),
          breadcrumbs.Crumb(question.prompt, None),
        ]),
        html.div([attribute.class("prose flex justify-between items-start")], [
          html.h1([], [html.text("Update question")]),
        ]),
        html.form([event.on_submit(submit), attribute.class("space-y-2")], [
          html.input([
            attribute.type_("hidden"),
            attribute.name("id"),
            attribute.value(question.id),
          ]),
          html.input([
            attribute.type_("hidden"),
            attribute.name("poll_id"),
            attribute.value(poll.id),
          ]),
          textarea.view(form, "prompt", "Question", Some(question.prompt)),
          html.button(
            [attribute.type_("submit"), attribute.class("btn btn-primary")],
            [html.text("Update question")],
          ),
        ]),
      ])
    _, _ -> html.text("loading..")
  }
}

fn fetch_poll(
  id: String,
  on_response handle_response: fn(Result(Poll, rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "http://localhost:3000/api/polls/" <> id
  let decoder = poll.poll_decoder()
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}

fn fetch_question(
  id: String,
  on_response handle_response: fn(Result(Question, rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "http://localhost:3000/api/questions/" <> id
  let decoder = question.question_decoder()
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}

fn update_question(
  question: UpdateQuestionData,
  on_response handle_response: fn(Result(Question, rsvp.Error)) -> msg,
) -> Effect(msg) {
  // TODO: use the shared package to define the routes and the helpers for both the client and the server
  let url = "http://localhost:3000/api/questions/" <> question.id
  let body =
    json.object([
      #("prompt", json.string(question.prompt)),
    ])
  let handler = rsvp.expect_json(question.question_decoder(), handle_response)

  rsvp.patch(url, body, handler)
}
