import components/input
import formal/form.{type Form}
import forms.{type SignUpFormData}
import gleam/http/response
import gleam/json
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import model.{type Model, type Msg}
import rsvp

pub fn view(form: Form(SignUpFormData)) -> Element(Msg) {
  let submit = fn(fields) {
    form
    |> form.add_values(fields)
    |> form.run
    |> model.UserSubmittedSignUpForm
  }

  html.div([], [
    html.h1([], [html.text("Sign up")]),
    html.form([event.on_submit(submit), attribute.class("space-y-2")], [
      input.view(form, is: "text", name: "email", label: "Email"),
      input.view(form, is: "password", name: "password", label: "Password"),
      html.button(
        [attribute.type_("submit"), attribute.class("btn btn-primary")],
        [html.text("Sign up")],
      ),
    ]),
  ])
}

pub fn update(
  model: Model,
  result: Result(SignUpFormData, Form(SignUpFormData)),
) -> #(Model, Effect(Msg)) {
  case result {
    Ok(values) -> #(model, sign_up(values, model.ApiAuthenticatedUser))
    Error(form) -> #(model.SignUp(app: model.app, form:), effect.none())
  }
}

fn sign_up(
  values: SignUpFormData,
  on_response handle_response: fn(Result(response.Response(String), rsvp.Error)) ->
    msg,
) -> Effect(msg) {
  let url = "http://localhost:8000/api/auth/sign-up"
  let body =
    json.object([
      #("email", json.string(values.email)),
      #("password", json.string(values.password)),
    ])
  let handler = rsvp.expect_ok_response(handle_response)

  rsvp.post(url, body, handler)
}
