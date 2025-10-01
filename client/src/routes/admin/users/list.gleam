import components/admin_nav
import gleam/dynamic/decode
import gleam/http/response.{type Response}
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import plinth/browser/window
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
  UserClickedDelete(String)
  UserConfirmedDelete(String)
  ApiDeletedUser(Result(Response(String), rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ApiReturnedUsers(Ok(users)) -> #(Model(..model, users:), effect.none())
    ApiReturnedUsers(Error(error)) -> {
      echo error
      #(model, effect.none())
    }
    UserClickedDelete(user_id) -> #(model, confirm_delete(user_id))
    UserConfirmedDelete(user_id) -> #(
      model,
      delete_user(user_id, ApiDeletedUser),
    )
    ApiDeletedUser(Ok(_res)) -> {
      #(model, fetch_users(ApiReturnedUsers))
    }
    ApiDeletedUser(Error(_)) -> #(model, effect.none())
  }
}

pub fn view(users: List(User)) -> Element(Msg) {
  html.div([attribute.class("space-y-4")], [
    admin_nav.view(),
    html.div([attribute.class("prose flex justify-between items-start")], [
      html.h1([], [html.text("Users")]),
    ]),
    html.table([attribute.class("table table-zebra w-full")], [
      html.thead([], [
        html.tr([], [
          html.th([], [html.text("Name")]),
          html.th([], [html.text("Email")]),
          html.th([], [html.text("Admin")]),
          html.th([], [html.text("Actions")]),
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
            html.td([], [
              case user.is_admin {
                True -> 
                  html.span([attribute.class("text-gray-400")], [
                    html.text("Protected")
                  ])
                False -> 
                  html.button([
                    attribute.class("btn btn-error btn-sm"),
                    event.on_click(UserClickedDelete(user.id))
                  ], [
                    html.text("Delete")
                  ])
              }
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

fn confirm_delete(user_id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    case window.confirm("Are you sure you want to delete this user?") {
      True -> dispatch(UserConfirmedDelete(user_id))
      False -> Nil
    }
  })
}

fn delete_user(
  id: String,
  on_response handle_response: fn(Result(Response(String), rsvp.Error)) -> Msg,
) -> Effect(Msg) {
  let url = "/api/users/" <> id
  let body = json.null()
  let handler = rsvp.expect_ok_response(handle_response)
  rsvp.delete(url, body, handler)
}
