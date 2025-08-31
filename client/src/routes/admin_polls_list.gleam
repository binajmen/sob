import gleam/dynamic/decode
import gleam/http/response.{type Response}
import gleam/list
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

// /// implementation of delete with proper error handling
// fn to_uri(uri_string: String) -> Result(uri.Uri, rsvp.Error) {
//   case uri_string {
//     "./" <> _ | "/" <> _ -> rsvp.parse_relative_uri(uri_string)
//     _ -> uri.parse(uri_string)
//   }
//   |> result.replace_error(rsvp.BadUrl(uri_string))
// }
//
// pub fn delete(url: String, handler: rsvp.Handler(Msg)) -> Effect(Msg) {
//   case to_uri(url) {
//     Ok(uri) ->
//       request.from_uri(uri)
//       |> result.map(fn(request) {
//         request
//         |> request.set_method(http.Delete)
//         |> rsvp.send(handler)
//       })
//       |> result.map_error(fn(_) {
//         use dispatch <- effect.from
//         dispatch(rsvp.BadUrl)
//       })
//       |> result.unwrap_both
//
//     Error(err) -> reject(err, handler)
//   }
// }

fn delete_poll(
  poll_id: String,
  on_response handle_response: fn(Result(Response(String), rsvp.Error)) -> Msg,
) -> Effect(Msg) {
  let url = "http://localhost:3000/api/polls/" <> poll_id
  let handler = rsvp.expect_ok_response(handle_response)
  rsvp.delete(url, handler)
}
