import gleam/json
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre/server_component
import rsvp
import shared/vote

pub const id = "75c7a6ce-7276-4407-af2b-7f16a226bbc3"

pub type Model {
  Model(vote: Option(vote.Vote))
}

pub fn init() -> #(Model, Effect(Msg)) {
  let model = Model(vote: None)
  #(model, fetch_vote(id, ApiReturnedVote))
}

fn fetch_vote(
  question_id: String,
  on_response handle_response: fn(Result(vote.Vote, rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "/api/votes/" <> question_id
  let decoder = vote.vote_decoder()
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}

pub type Msg {
  UserIsVoting(String)
  ApiReturnedVote(Result(vote.Vote, rsvp.Error))
  ApiRegisteredVote(Result(vote.Vote, rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserIsVoting(vote) -> #(model, cast_vote(id, vote, ApiRegisteredVote))

    ApiReturnedVote(Ok(vote)) -> #(Model(vote: Some(vote)), effect.none())
    ApiReturnedVote(Error(_)) -> #(model, effect.none())

    ApiRegisteredVote(Ok(vote)) -> #(Model(vote: Some(vote)), effect.none())
    ApiRegisteredVote(Error(_)) -> #(model, effect.none())
  }
}

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("prose")], [
    html.h1([], [html.text("Live")]),
    server_component.script(),
    server_component.element(
      [
        server_component.route("/ws/live"),
        server_component.method(server_component.WebSocket),
      ],
      [
        case model.vote {
          Some(vote) -> view_registered_vote(vote)
          None -> view_controls()
        },
      ],
    ),
  ])
}

fn view_controls() -> Element(Msg) {
  html.div([attribute.class("space-x-4")], [
    html.button(
      [
        attribute.id("yes"),
        attribute.class("btn btn-primary btn-sm"),
        event.on_click(UserIsVoting("yes")),
      ],
      [
        html.text("Agree"),
      ],
    ),
    html.button(
      [
        attribute.id("no"),
        attribute.class("btn btn-primary btn-sm"),
        event.on_click(UserIsVoting("no")),
      ],
      [
        html.text("Disagree"),
      ],
    ),
    html.button(
      [
        attribute.id("blank"),
        attribute.class("btn btn-primary btn-sm"),
        event.on_click(UserIsVoting("blank")),
      ],
      [html.text("Abstain")],
    ),
  ])
}

fn cast_vote(
  question_id: String,
  vote: String,
  on_response handle_response: fn(Result(vote.Vote, rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "/api/votes"
  let body =
    json.object([
      #("question_id", json.string(question_id)),
      #("vote", json.string(vote)),
    ])
  let decoder = vote.vote_decoder()
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.post(url, body, handler)
}

fn view_registered_vote(vote: vote.Vote) -> Element(msg) {
  html.div([], [
    html.text("You have voted!"),
    html.text(vote.vote |> vote.vote_type_to_string()),
  ])
}
