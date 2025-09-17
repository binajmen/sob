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
  Model(form: Form(SignUpFormData))
}

pub type SignUpFormData {
  SignUpFormData(
    email: String,
    password: String,
    first_name: String,
    last_name: String,
  )
}

pub fn sign_up_form() -> Form(SignUpFormData) {
  form.new({
    use email <- form.field("email", form.parse_email)
    use password <- form.field(
      "password",
      form.parse_string |> form.check_not_empty,
    )
    use first_name <- form.field(
      "first_name",
      form.parse_string |> form.check_not_empty,
    )
    use last_name <- form.field(
      "last_name",
      form.parse_string |> form.check_not_empty,
    )
    form.success(SignUpFormData(email:, password:, first_name:, last_name:))
  })
}

pub fn init() -> #(Model, Effect(Msg)) {
  let model = Model(form: sign_up_form())
  #(model, effect.none())
}

pub type Msg {
  UserSubmittedSignUpForm(Result(SignUpFormData, Form(SignUpFormData)))
  ApiAuthenticatedUser(Result(response.Response(String), rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserSubmittedSignUpForm(result) ->
      case result {
        Ok(values) -> #(model, sign_up(values, ApiAuthenticatedUser))
        Error(form) -> #(Model(form:), effect.none())
      }
    ApiAuthenticatedUser(Ok(_)) -> #(
      model,
      modem.push(router.to_path(router.Index), None, None),
    )
    ApiAuthenticatedUser(Error(_)) -> #(
      Model(
        form: sign_up_form()
        |> form.add_error(
          "password",
          form.CustomError("Email or password is incorrect"),
        ),
      ),
      effect.none(),
    )
  }
}

pub fn view(form: Form(SignUpFormData)) -> Element(Msg) {
  let submit = fn(fields) {
    form
    |> form.add_values(fields)
    |> form.run
    |> UserSubmittedSignUpForm
  }

  html.div([], [
    html.h1([], [html.text("Sign up")]),
    html.form(
      [
        event.on_submit(submit),
        attribute.class("space-y-2"),
        attribute.autocomplete("off"),
      ],
      [
        input.view(form, "text", "email", "Email", None),
        input.view(form, "password", "password", "Password", None),
        input.view(form, "text", "first_name", "First name", None),
        input.view(form, "text", "last_name", "Last name", None),
        html.button(
          [attribute.type_("submit"), attribute.class("btn btn-primary")],
          [html.text("Sign up")],
        ),
      ],
    ),
  ])
}

fn sign_up(
  values: SignUpFormData,
  on_response handle_response: fn(Result(response.Response(String), rsvp.Error)) ->
    msg,
) -> Effect(msg) {
  let url = "/api/auth/sign-up"
  let body =
    json.object([
      #("email", json.string(values.email)),
      #("password", json.string(values.password)),
      #("first_name", json.string(values.first_name)),
      #("last_name", json.string(values.last_name)),
    ])
  let handler = rsvp.expect_ok_response(handle_response)

  rsvp.post(url, body, handler)
}
