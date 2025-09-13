import components/breadcrumbs
import components/textarea
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
    ApiQuestionCreated(Ok(_)) -> {
      let assert Ok(poll) = option.to_result(model.poll, "missing poll")
      #(
        model,
        modem.push(router.to_path(router.AdminQuestions(poll.id)), None, None),
      )
    }
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
          breadcrumbs.Crumb("Create", None),
        ]),
        html.div([attribute.class("prose flex justify-between items-start")], [
          html.h1([], [html.text("Create question")]),
        ]),
        html.form([event.on_submit(submit), attribute.class("space-y-2")], [
          html.input([
            attribute.type_("hidden"),
            attribute.name("poll_id"),
            attribute.value(poll.id),
          ]),
          textarea.view(form, "prompt", "Question", None),
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
