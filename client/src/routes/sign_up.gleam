import components/button
import components/input
import formal/form.{type Form}
import forms
import gleam/http/response
import gleam/json
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import model.{type Model, type Msg}
import rsvp

pub fn view(form: Form(forms.SignUpFormData)) -> Element(Msg) {
  let submit = fn(fields) {
    form |> form.add_values(fields) |> form.run |> model.UserSubmittedSignUpForm
  }

  html.div([attribute.class("p-4")], [
    html.h1([], [html.text("Sign up")]),
    html.form(
      [
        attribute.method("POST"),
        event.on_submit(submit),
        attribute.class("flex flex-col gap-4"),
      ],
      [
        input.view(form, is: "text", name: "email", label: "Email"),
        input.view(form, is: "password", name: "password", label: "Password"),
        button.submit(label: "Sign up"),
      ],
    ),
  ])
}

pub fn update(
  model: Model,
  result: Result(forms.SignUpFormData, form.Form(forms.SignUpFormData)),
) -> #(Model, Effect(Msg)) {
  case result {
    Ok(values) -> #(model, sign_up(values, model.ApiAuthenticatedUser))
    Error(form) -> #(model.SignUp(base: model.base, form:), effect.none())
  }
}

fn sign_up(
  values: forms.SignUpFormData,
  on_response handle_response: fn(Result(response.Response(String), rsvp.Error)) ->
    msg,
) -> Effect(msg) {
  let url = "http://localhost:8000/api/auth/sign-up"
  let handler = rsvp.expect_ok_response(handle_response)
  let body =
    json.object([
      #("email", json.string(values.email)),
      #("password", json.string(values.password)),
    ])

  rsvp.post(url, body, handler)
}
