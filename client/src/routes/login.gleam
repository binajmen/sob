import components/button
import components/input
import formal/form.{type Form}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import model.{type Model, type Msg, Model}

pub fn view(form: Form) -> Element(Msg) {
  html.div([attribute.class("p-4")], [
    html.h1([], [html.text("Login")]),
    html.form(
      [
        attribute.class("flex flex-col gap-4"),
        event.on_submit(model.UserSubmittedLoginForm),
      ],
      [
        input.view(form, is: "text", name: "username", label: "Username"),
        input.view(form, is: "password", name: "password", label: "Password"),
        button.submit(label: "Login"),
      ],
    ),
  ])
}

type LoginData {
  LoginData(username: String, password: String)
}

fn decode_login_data(values: List(#(String, String))) -> Result(LoginData, Form) {
  form.decoding({
    use username <- form.parameter
    use password <- form.parameter
    LoginData(username:, password:)
  })
  |> form.with_values(values)
  |> form.field("username", form.string |> form.and(form.must_not_be_empty))
  |> form.field(
    "password",
    form.string
      |> form.and(form.must_equal("arst", because: "Password must be 'arst'")),
  )
  |> form.finish
}

pub fn update(
  model: Model,
  values: List(#(String, String)),
) -> #(Model, Effect(Msg)) {
  case decode_login_data(values) {
    Ok(LoginData(username:, password: _)) -> {
      echo username
      #(Model(..model, login_form: form.new()), effect.none())
    }
    Error(form) -> #(Model(..model, login_form: form), effect.none())
  }
}
