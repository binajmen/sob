import components/input
import formal/form.{type Form}
import gleam/http/response.{type Response}
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

pub type Model {
  Model(poll: Option(Poll), form: Form(CreateQuestionData))
}

pub type CreateQuestionData {
  CreateQuestionData(poll_id: String, prompt: String)
}

pub fn create_question_form() -> Form(CreateQuestionData) {
  form.new({
    use poll_id <- form.field("poll_id", form.parse_string)
    use prompt <- form.field("prompt", form.parse_string)
    form.success(CreateQuestionData(poll_id:, prompt:))
  })
}

pub fn init(id: String) -> #(Model, Effect(Msg)) {
  let model = Model(poll: None, form: create_question_form())
  #(model, fetch_poll(id, ApiReturnedPoll))
}

pub type Msg {
  UserSubmittedForm(Result(CreateQuestionData, Form(CreateQuestionData)))
  ApiQuestionCreated(Result(Response(String), rsvp.Error))
  ApiReturnedPoll(Result(Poll, rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserSubmittedForm(result) ->
      case result {
        Ok(values) -> #(model, create_question(values, ApiQuestionCreated))
        Error(form) -> #(Model(..model, form:), effect.none())
      }
    ApiQuestionCreated(Ok(_)) -> #(
      model,
      modem.push(router.to_path(router.AdminPolls), None, None),
    )
    ApiQuestionCreated(Error(_)) -> #(model, effect.none())
    ApiReturnedPoll(Ok(poll)) -> #(
      Model(..model, poll: Some(poll)),
      effect.none(),
    )
    ApiReturnedPoll(Error(_)) -> #(model, effect.none())
  }
}

pub fn view(poll: Option(Poll), form: Form(CreateQuestionData)) -> Element(Msg) {
  let submit = fn(fields) {
    form
    |> form.add_values(fields)
    |> form.run
    |> UserSubmittedForm
  }

  case poll {
    None -> html.text("loading..")
    Some(poll) ->
      html.div([], [
        html.h1([], [html.text("Create a question for the poll: " <> poll.name)]),
        html.form([event.on_submit(submit), attribute.class("space-y-2")], [
          html.input([
            attribute.type_("hidden"),
            attribute.name("poll_id"),
            attribute.value(poll.id),
          ]),
          input.view(form, is: "text", name: "prompt", label: "Question"),
          html.button(
            [attribute.type_("submit"), attribute.class("btn btn-primary")],
            [html.text("Create question")],
          ),
        ]),
      ])
  }
}

fn create_question(
  values: CreateQuestionData,
  on_response handle_response: fn(Result(response.Response(String), rsvp.Error)) ->
    msg,
) -> Effect(msg) {
  // TODO: use the shared package to define the routes and the helpers for both the client and the server
  let url = "http://localhost:3000/api/questions"
  let body =
    json.object([
      #("poll_id", json.string(values.poll_id)),
      #("prompt", json.string(values.prompt)),
    ])
  let handler = rsvp.expect_ok_response(handle_response)

  rsvp.post(url, body, handler)
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
