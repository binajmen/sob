import gleam/dynamic/decode
import gleam/list
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
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
    ApiReturnedPolls(Ok(polls)) ->
      #(Model(polls: polls), effect.none())
      |> echo
    ApiReturnedPolls(Error(_)) ->
      #(model, effect.none())
      |> echo
  }
}

pub fn view(polls: List(Poll)) -> Element(Msg) {
  html.div([], [
    html.h1([], [html.text("Admin Polls")]),
    html.ul(
      [],
      list.map(polls, fn(poll) {
        html.li([], [html.text(poll.id <> " - " <> poll.name)])
      }),
    ),
  ])
}

fn fetch_polls(
  on_response handle_response: fn(Result(List(Poll), rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "http://localhost:8000/api/polls"
  let decoder = decode.list(poll.poll_decoder()) |> decode.map(list.take(_, 10))
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}
