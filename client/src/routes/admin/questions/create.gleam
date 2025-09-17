import components/textarea
import formal/form.{type Form}
import gleam/http/response.{type Response}
import gleam/json
import gleam/option.{None}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import modem
import router
import rsvp

pub type Model {
  Model(form: Form(CreateQuestionData))
}

pub type CreateQuestionData {
  CreateQuestionData(prompt: String)
}

pub fn create_question_form() -> Form(CreateQuestionData) {
  form.new({
    use prompt <- form.field("prompt", form.parse_string)
    form.success(CreateQuestionData(prompt:))
  })
}

pub fn init() -> #(Model, Effect(Msg)) {
  let model = Model(form: create_question_form())
  #(model, effect.none())
}

pub type Msg {
  UserSubmittedForm(Result(CreateQuestionData, Form(CreateQuestionData)))
  ApiQuestionCreated(Result(Response(String), rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserSubmittedForm(result) ->
      case result {
        Ok(values) -> #(model, create_question(values, ApiQuestionCreated))
        Error(form) -> #(Model(..model, form:), effect.none())
      }
    ApiQuestionCreated(Ok(_)) -> {
      #(
        model,
        modem.push(router.to_path(router.AdminQuestionsList), None, None),
      )
    }
    ApiQuestionCreated(Error(_)) -> #(model, effect.none())
  }
}

pub fn view(form: Form(CreateQuestionData)) -> Element(Msg) {
  let submit = fn(fields) {
    form
    |> form.add_values(fields)
    |> form.run
    |> UserSubmittedForm
  }

  html.div([attribute.class("space-y-4")], [
    html.div([attribute.class("prose flex justify-between items-start")], [
      html.h1([], [html.text("Create question")]),
    ]),
    html.form([event.on_submit(submit), attribute.class("space-y-2")], [
      textarea.view(form, "prompt", "Question", None),
      html.button(
        [attribute.type_("submit"), attribute.class("btn btn-primary")],
        [html.text("Create question")],
      ),
    ]),
  ])
}

fn create_question(
  values: CreateQuestionData,
  on_response handle_response: fn(Result(response.Response(String), rsvp.Error)) ->
    msg,
) -> Effect(msg) {
  let url = "/api/questions"
  let body =
    json.object([
      #("prompt", json.string(values.prompt)),
    ])
  let handler = rsvp.expect_ok_response(handle_response)

  rsvp.post(url, body, handler)
}
