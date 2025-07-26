import gleam/dynamic/decode
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import model.{type Model, type Msg}
import router
import rsvp
import shared/poll.{type Poll}

pub fn init(model: Option(Model)) -> #(Model, Effect(Msg)) {
  case model {
    None -> init_empty()
    Some(model) -> init_with_model(model)
  }
}

fn init_empty() -> #(Model, Effect(Msg)) {
  let app = model.App(route: router.AdminPolls, lang: "en")
  #(
    model.AdminPolls(app:, polls: []),
    fetch_polls(on_response: model.ApiReturnedPolls),
  )
}

fn init_with_model(model: Model) -> #(Model, Effect(Msg)) {
  let app = model.App(..model.app, route: router.AdminPolls)
  #(
    model.AdminPolls(app:, polls: []),
    fetch_polls(on_response: model.ApiReturnedPolls),
  )
}

pub fn view(polls: List(Poll)) -> Element(Msg) {
  html.div([], [
    html.h1([], [html.text("Polls")]),
    html.ul(
      [],
      list.map(polls, fn(poll) {
        html.li([], [html.text(poll.id <> " - " <> poll.name)])
      }),
    ),
  ])
}

pub fn fetch_polls(
  on_response handle_response: fn(Result(List(Poll), rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "http://localhost:8000/api/admin/polls"
  let decoder = decode.list(poll.poll_decoder()) |> decode.map(list.take(_, 10))
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}
