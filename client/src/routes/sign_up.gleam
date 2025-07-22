import components/button
import components/input
import formal/form.{type Form}
import gleam/http/response
import gleam/json
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import model.{type Model, type Msg, Model}
import rsvp

pub fn view(form: Form) -> Element(Msg) {
  html.div([attribute.class("p-4")], [
    html.h1([], [html.text("Sign up")]),
    html.form(
      [
        attribute.class("flex flex-col gap-4"),
        event.on_submit(model.UserSubmittedSignUpForm),
      ],
      [
        input.view(form, is: "text", name: "email", label: "Email"),
        input.view(form, is: "password", name: "password", label: "Password"),
        button.submit(label: "Sign up"),
      ],
    ),
  ])
}

type FormData {
  FormData(email: String, password: String)
}

fn decode_formdata(values: List(#(String, String))) -> Result(FormData, Form) {
  form.decoding({
    use email <- form.parameter
    use password <- form.parameter
    FormData(email:, password:)
  })
  |> form.with_values(values)
  |> form.field("email", form.string |> form.and(form.must_not_be_empty))
  |> form.field("password", form.string |> form.and(form.must_not_be_empty))
  |> form.finish
}

pub fn update(
  model: Model,
  values: List(#(String, String)),
) -> #(Model, Effect(Msg)) {
  case decode_formdata(values) {
    Ok(FormData(email:, password:)) -> #(
      Model(..model, sign_up_form: form.new()),
      sign_up(email, password, model.ApiAuthenticatedUser),
    )
    Error(form) -> #(Model(..model, sign_up_form: form), effect.none())
  }
}

fn sign_up(
  email email: String,
  password password: String,
  on_response handle_response: fn(Result(response.Response(String), rsvp.Error)) ->
    msg,
) -> Effect(msg) {
  let url = "http://localhost:8000/api/auth/sign-up"
  let handler = rsvp.expect_ok_response(handle_response)
  let body =
    json.object([
      #("email", json.string(email)),
      #("password", json.string(password)),
    ])

  rsvp.post(url, body, handler)
}
