import components/input
import formal/form.{type Form}
import gleam/http/response
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
  Model(form: Form(GuestFormData))
}

pub type GuestFormData {
  GuestFormData(first_name: String, last_name: String)
}

pub fn register_form() -> Form(GuestFormData) {
  form.new({
    use first_name <- form.field(
      "first_name",
      form.parse_string |> form.check_not_empty,
    )
    use last_name <- form.field(
      "last_name",
      form.parse_string |> form.check_not_empty,
    )
    form.success(GuestFormData(first_name:, last_name:))
  })
}

pub fn init() -> #(Model, Effect(Msg)) {
  let model = Model(form: register_form())
  #(model, effect.none())
}

pub type Msg {
  UserSubmittedGuestForm(Result(GuestFormData, Form(GuestFormData)))
  ApiAuthenticatedUser(Result(response.Response(String), rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserSubmittedGuestForm(result) ->
      case result {
        Ok(values) -> #(model, register(values, ApiAuthenticatedUser))
        Error(form) -> #(Model(form:), effect.none())
      }
    ApiAuthenticatedUser(Ok(_)) -> #(
      model,
      modem.push(router.to_path(router.AdminPolls), None, None),
    )
    ApiAuthenticatedUser(Error(_)) -> #(
      Model(form: register_form()),
      effect.none(),
    )
  }
}

pub fn view(form: Form(GuestFormData)) -> Element(Msg) {
  let submit = fn(fields) {
    form
    |> form.add_values(fields)
    |> form.run
    |> UserSubmittedGuestForm
  }

  html.div([], [
    html.h1([], [html.text("Guest registration")]),
    html.form(
      [
        event.on_submit(submit),
        attribute.class("space-y-2"),
        attribute.autocomplete("off"),
      ],
      [
        input.view(form, is: "text", name: "first_name", label: "First name"),
        input.view(form, is: "text", name: "last_name", label: "Last name"),
        html.button(
          [attribute.type_("submit"), attribute.class("btn btn-primary")],
          [html.text("Sign up as guest")],
        ),
      ],
    ),
  ])
}

fn register(
  values: GuestFormData,
  on_response handle_response: fn(Result(response.Response(String), rsvp.Error)) ->
    msg,
) -> Effect(msg) {
  let url = "http://localhost:3000/api/auth/guest"
  let body =
    json.object([
      #("first_name", json.string(values.first_name)),
      #("last_name", json.string(values.last_name)),
    ])
  let handler = rsvp.expect_ok_response(handle_response)

  rsvp.post(url, body, handler)
}
