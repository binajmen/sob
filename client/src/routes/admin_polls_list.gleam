import components/breadcrumbs
import gleam/dynamic/decode
import gleam/http/response.{type Response}
import gleam/json
import gleam/list
import gleam/option.{Some}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import plinth/browser/window
import router
import rsvp
import shared/poll.{type Poll}

pub type Model {
  Model(polls: List(Poll))
}

pub fn init() -> #(Model, Effect(Msg)) {
  let model = Model(polls: [])
  #(model, fetch_polls(ApiReturnedPolls))
}

pub type Msg {
  UserClickedDelete(String)
  UserConfirmedDelete(String)
  ApiReturnedPolls(Result(List(Poll), rsvp.Error))
  ApiDeletedPoll(Result(Response(String), rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserClickedDelete(poll_id) -> #(model, confirm_delete(poll_id))
    UserConfirmedDelete(poll_id) -> #(
      model,
      delete_poll(poll_id, ApiDeletedPoll),
    )
    ApiReturnedPolls(Ok(polls)) -> #(Model(polls: polls), effect.none())
    ApiReturnedPolls(Error(_)) -> #(model, effect.none())
    ApiDeletedPoll(_) -> #(model, fetch_polls(ApiReturnedPolls))
  }
}

pub fn view(polls: List(Poll)) -> Element(Msg) {
  html.div([], [
    breadcrumbs.view([
      breadcrumbs.Crumb("Admin", Some(router.to_path(router.Admin))),
      breadcrumbs.Crumb("Polls", Some(router.to_path(router.AdminPolls))),
    ]),
    html.div([attribute.class("prose flex justify-between items-start")], [
      html.h1([], [html.text("Admin Polls")]),
      html.a([router.href(router.AdminPollsCreate)], [
        html.button([attribute.class("btn btn-primary")], [
          html.text("Create Poll"),
        ]),
      ]),
    ]),
    html.table([attribute.class("table table-zebra w-auto")], [
      html.thead([], [
        html.tr([], [
          html.th([], []),
          html.th([], [html.text("Name")]),
          html.th([], []),
        ]),
      ]),
      html.tbody(
        [],
        list.map(polls, fn(poll) {
          html.tr([], [
            html.th([], [html.text(poll.id)]),
            html.td([], [html.text(poll.name)]),
            html.td([attribute.class("space-x-2")], [
              html.a([router.href(router.AdminPollsView(poll.id))], [
                html.button([attribute.class("btn btn-primary btn-sm")], [
                  html.text("View"),
                ]),
              ]),
              html.button(
                [
                  attribute.class("btn btn-error btn-sm"),
                  event.on_click(UserClickedDelete(poll.id)),
                ],
                [
                  html.text("Delete"),
                ],
              ),
            ]),
          ])
        }),
      ),
    ]),
  ])
}

fn confirm_delete(poll_id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    case window.confirm("Are you sure you want to delete this poll?") {
      True -> dispatch(UserConfirmedDelete(poll_id))
      False -> Nil
    }
  })
}

fn fetch_polls(
  on_response handle_response: fn(Result(List(Poll), rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "http://localhost:3000/api/polls"
  let decoder = decode.list(poll.poll_decoder()) |> decode.map(list.take(_, 10))
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}

fn delete_poll(
  poll_id: String,
  on_response handle_response: fn(Result(Response(String), rsvp.Error)) -> Msg,
) -> Effect(Msg) {
  let url = "http://localhost:3000/api/polls/" <> poll_id
  let body = json.null()
  let handler = rsvp.expect_ok_response(handle_response)
  rsvp.delete(url, body, handler)
}
