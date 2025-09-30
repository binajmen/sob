import components/checkbox
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
  Model(form: Form(GuestFormData), is_proxy: Bool)
}

pub type GuestFormData {
  GuestFormData(
    first_name: String,
    last_name: String,
    is_proxy: Bool,
    proxy_first_name: String,
    proxy_last_name: String,
  )
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
    use is_proxy <- form.field("is_proxy", form.parse_checkbox)
    use proxy_first_name <- form.field("proxy_first_name", form.parse_string)
    use proxy_last_name <- form.field("proxy_last_name", form.parse_string)
    form.success(GuestFormData(
      first_name:,
      last_name:,
      is_proxy:,
      proxy_first_name:,
      proxy_last_name:,
    ))
  })
}

pub fn init() -> #(Model, Effect(Msg)) {
  let model = Model(form: register_form(), is_proxy: False)
  #(model, effect.none())
}

pub type Msg {
  UserToggledProxy(Bool)
  UserSubmittedGuestForm(Result(GuestFormData, Form(GuestFormData)))
  ApiAuthenticatedUser(Result(response.Response(String), rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserToggledProxy(is_proxy) -> #(
      Model(..model, is_proxy: is_proxy),
      effect.none(),
    )
    UserSubmittedGuestForm(result) ->
      case result {
        Ok(values) -> #(model, register(values, ApiAuthenticatedUser))
        Error(form) -> #(Model(..model, form: form), effect.none())
      }
    ApiAuthenticatedUser(Ok(_)) -> #(
      model,
      modem.push(router.to_path(router.Poll), None, None),
    )
    ApiAuthenticatedUser(Error(_)) -> #(
      Model(form: register_form(), is_proxy: False),
      effect.none(),
    )
  }
}

pub fn view(model: Model) -> Element(Msg) {
  let submit = fn(fields) {
    model.form
    |> form.add_values(fields)
    |> form.run
    |> UserSubmittedGuestForm
  }

  html.div([attribute.class("prose")], [
    html.h1([], [html.text("Guest registration")]),
    html.form(
      [
        event.on_submit(submit),
        attribute.class("space-y-2"),
        attribute.autocomplete("off"),
      ],
      [
        input.view(model.form, "text", "first_name", "First name", None),
        input.view(model.form, "text", "last_name", "Last name", None),
        checkbox.view(
          model.form,
          "is_proxy",
          "I'm the proxy of someone",
          model.is_proxy,
          UserToggledProxy,
        ),
        case model.is_proxy {
          True ->
            html.div([attribute.class("space-y-2 pl-4 border-l-2 border-gray-200")], [
              html.h3([attribute.class("text-sm font-medium")], [
                html.text("Person you're representing:")
              ]),
              input.view(
                model.form,
                "text",
                "proxy_first_name",
                "Their first name",
                None,
              ),
              input.view(
                model.form,
                "text",
                "proxy_last_name",
                "Their last name",
                None,
              ),
            ])
          False -> html.div([], [])
        },
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
  let url = "/api/auth/guest"
  let body =
    json.object([
      #("first_name", json.string(values.first_name)),
      #("last_name", json.string(values.last_name)),
      #("is_proxy", json.bool(values.is_proxy)),
      #("proxy_first_name", json.string(values.proxy_first_name)),
      #("proxy_last_name", json.string(values.proxy_last_name)),
    ])
  let handler = rsvp.expect_ok_response(handle_response)

  rsvp.post(url, body, handler)
}
