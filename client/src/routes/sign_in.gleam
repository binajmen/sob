import components/button
import components/input
import formal/form.{type Form}
import forms.{type SignInFormData}
import gleam/http/response
import gleam/json
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import model.{type Model, type Msg}
import rsvp

pub fn view(form: Form(SignInFormData)) -> Element(Msg) {
  let submit = fn(fields) {
    form |> form.add_values(fields) |> form.run |> model.UserSubmittedSignInForm
  }

  html.div([attribute.class("p-4")], [
    html.h1([], [html.text("Sign in")]),
    html.form(
      [
        attribute.method("POST"),
        event.on_submit(submit),
        attribute.class("flex flex-col gap-4"),
      ],
      [
        input.view(form, is: "text", name: "email", label: "Email"),
        input.view(form, is: "password", name: "password", label: "Password"),
        button.submit(label: "Sign in"),
      ],
    ),
  ])
}

pub fn update(
  model: Model,
  result: Result(SignInFormData, Form(SignInFormData)),
) -> #(Model, Effect(Msg)) {
  case result {
    Ok(values) -> #(model, sign_in(values, model.ApiAuthenticatedUser))
    Error(form) -> #(model.SignIn(app: model.app, form:), effect.none())
  }
}

fn sign_in(
  values: SignInFormData,
  on_response handle_response: fn(Result(response.Response(String), rsvp.Error)) ->
    msg,
) -> Effect(msg) {
  let url = "http://localhost:8000/api/auth/sign-in"
  let handler = rsvp.expect_ok_response(handle_response)
  let body =
    json.object([
      #("email", json.string(values.email)),
      #("password", json.string(values.password)),
    ])

  rsvp.post(url, body, handler)
}
