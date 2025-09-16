import gleam/dynamic/decode
import gleam/list
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
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
  ApiReturnedPolls(Result(List(Poll), rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ApiReturnedPolls(Ok(polls)) -> #(Model(polls: polls), effect.none())
    ApiReturnedPolls(Error(_)) -> #(model, effect.none())
  }
}

pub fn view(polls: List(Poll)) -> Element(Msg) {
  html.div([attribute.class("prose")], [
    html.h1([], [html.text("Polls")]),
    html.table([attribute.class("table table-zebra w-auto")], [
      html.thead([], [
        html.tr([], [
          html.th([], [html.text("Name")]),
          html.th([], []),
        ]),
      ]),
      html.tbody(
        [],
        list.map(polls, fn(poll) {
          html.tr([], [
            html.td([], [html.text(poll.name)]),
            html.td([attribute.class("space-x-2")], [
              html.a([router.href(router.Poll(poll.id))], [
                html.button([attribute.class("btn btn-primary btn-sm")], [
                  html.text("Participate"),
                ]),
              ]),
            ]),
          ])
        }),
      ),
    ]),
  ])
}

fn fetch_polls(
  on_response handle_response: fn(Result(List(Poll), rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "/api/polls"
  let decoder = decode.list(poll.poll_decoder())
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}
