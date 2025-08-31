import components/breadcrumbs
import components/input
import formal/form.{type Form}
import gleam/http/response
import gleam/json
import gleam/option.{None, Some}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import modem
import router
import rsvp

pub type Model {
  Model(form: Form(CreatePollData))
}

pub type CreatePollData {
  CreatePollData(name: String)
}

pub fn create_poll_form() -> Form(CreatePollData) {
  form.new({
    use name <- form.field("name", form.parse_string)
    form.success(CreatePollData(name:))
  })
}

pub fn init() -> #(Model, Effect(Msg)) {
  let model = Model(form: create_poll_form())
  #(model, effect.none())
}

pub type Msg {
  UserSubmittedForm(Result(CreatePollData, Form(CreatePollData)))
  ApiPollCreated(Result(response.Response(String), rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserSubmittedForm(result) ->
      case result {
        Ok(values) -> #(model, create_poll(values, ApiPollCreated))
        Error(form) -> #(Model(form:), effect.none())
      }
    ApiPollCreated(Ok(_)) -> #(
      model,
      modem.push(router.to_path(router.AdminPolls), None, None),
    )
    ApiPollCreated(Error(_)) -> #(model, effect.none())
  }
}

pub fn view(form: Form(CreatePollData)) -> Element(Msg) {
  let submit = fn(fields) {
    form
    |> form.add_values(fields)
    |> form.run
    |> UserSubmittedForm
  }

  html.div([], [
    breadcrumbs.view([
      breadcrumbs.Crumb("Admin", Some(router.to_path(router.Admin))),
      breadcrumbs.Crumb("Polls", Some(router.to_path(router.AdminPolls))),
      breadcrumbs.Crumb("Create", None),
    ]),
    html.h1([], [html.text("Create poll")]),
    html.form([event.on_submit(submit), attribute.class("space-y-2")], [
      input.view(form, "text", "name", "Name", None),
      html.button(
        [attribute.type_("submit"), attribute.class("btn btn-primary")],
        [html.text("Create poll")],
      ),
    ]),
  ])
}

fn create_poll(
  values: CreatePollData,
  on_response handle_response: fn(Result(response.Response(String), rsvp.Error)) ->
    msg,
) -> Effect(msg) {
  // TODO: use the shared package to define the routes and the helpers for both the client and the server
  let url = "http://localhost:3000/api/polls"
  let body = json.object([#("name", json.string(values.name))])
  let handler = rsvp.expect_ok_response(handle_response)

  rsvp.post(url, body, handler)
}
