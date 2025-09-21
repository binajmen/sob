import gleam/dynamic/decode
import gleam/list
import gleam/option.{None, Some}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import rsvp
import shared/user.{type User}

pub type Model {
  Model(users: List(User))
}

pub fn init() -> #(Model, Effect(Msg)) {
  let model = Model(users: [])
  #(model, fetch_users(ApiReturnedUsers))
}

pub type Msg {
  ApiReturnedUsers(Result(List(User), rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ApiReturnedUsers(Ok(users)) -> #(
      Model(..model, users:),
      effect.none(),
    )
    ApiReturnedUsers(Error(error)) -> {
      echo error
      #(model, effect.none())
    }
  }
}

pub fn view(users: List(User)) -> Element(Msg) {
  html.div([attribute.class("space-y-4")], [
    html.div([attribute.class("prose flex justify-between items-start")], [
      html.h1([], [html.text("Users")]),
    ]),
    html.table([attribute.class("table table-zebra w-full")], [
      html.thead([], [
        html.tr([], [
          html.th([], [html.text("Name")]),
          html.th([], [html.text("Email")]),
          html.th([], [html.text("Admin")]),
        ]),
      ]),
      html.tbody(
        [],
        list.map(users, fn(user) {
          html.tr([], [
            html.td([], [
              html.text(format_user_name(user.first_name, user.last_name)),
            ]),
            html.td([], [
              html.text(case user.email {
                Some(email) -> email
                None -> "Guest"
              }),
            ]),
            html.td([], [
              case user.is_admin {
                True ->
                  html.span([attribute.class("badge badge-success")], [
                    html.text("Admin"),
                  ])
                False ->
                  html.span([attribute.class("badge badge-neutral")], [
                    html.text("User"),
                  ])
              },
            ]),
          ])
        }),
      ),
    ]),
  ])
}

fn format_user_name(
  first_name: option.Option(String),
  last_name: option.Option(String),
) -> String {
  case first_name, last_name {
    Some(first), Some(last) -> first <> " " <> last
    Some(first), None -> first
    None, Some(last) -> last
    None, None -> "Anonymous"
  }
}



fn fetch_users(
  on_response handle_response: fn(Result(List(User), rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "/api/users"
  let decoder = decode.list(user.user_decoder())
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}