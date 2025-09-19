import components/input
import config
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
  Model(form: Form(SignInFormData))
}

pub type SignInFormData {
  SignInFormData(email: String, password: String)
}

pub fn sign_in_form() -> Form(SignInFormData) {
  form.new({
    use email <- form.field("email", form.parse_email)
    use password <- form.field(
      "password",
      form.parse_string |> form.check_not_empty,
    )
    form.success(SignInFormData(email:, password:))
  })
}

pub fn init() -> #(Model, Effect(Msg)) {
  let model = Model(form: sign_in_form())
  #(model, effect.none())
}

pub type Msg {
  UserSubmittedSignInForm(Result(SignInFormData, Form(SignInFormData)))
  ApiAuthenticatedUser(Result(response.Response(String), rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserSubmittedSignInForm(result) ->
      case result {
        Ok(values) -> #(model, sign_in(values, ApiAuthenticatedUser))
        Error(form) -> #(Model(form:), effect.none())
      }
    ApiAuthenticatedUser(Ok(_)) -> #(
      model,
      modem.push(router.to_path(router.Index), None, None),
    )
    ApiAuthenticatedUser(Error(_)) -> #(
      Model(
        form: sign_in_form()
        |> form.add_error(
          "password",
          form.CustomError("Email or password is incorrect"),
        ),
      ),
      effect.none(),
    )
  }
}

pub fn view(form: Form(SignInFormData)) -> Element(Msg) {
  let submit = fn(fields) {
    form
    |> form.add_values(fields)
    |> form.run
    |> UserSubmittedSignInForm
  }

  html.div([], [
    html.h1([], [html.text("Sign in")]),
    html.form(
      [
        event.on_submit(submit),
        attribute.class("space-y-2"),
        attribute.autocomplete("off"),
      ],
      [
        input.view(form, "text", "email", "Email", None),
        input.view(form, "password", "password", "Password", None),
        html.button(
          [attribute.type_("submit"), attribute.class("btn btn-primary")],
          [html.text("Sign in")],
        ),
      ],
    ),
  ])
}

fn sign_in(
  values: SignInFormData,
  on_response handle_response: fn(Result(response.Response(String), rsvp.Error)) ->
    msg,
) -> Effect(msg) {
  let url = "/api/auth/sign-in"
  let body =
    json.object([
      #("email", json.string(values.email)),
      #("password", json.string(values.password)),
    ])
  let handler = rsvp.expect_ok_response(handle_response)

  rsvp.post(url, body, handler)
}
