import gleam/dynamic/decode
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

pub type Model {
  Model(question_id: Option(String), vote: Option(vote.Vote))
}

pub fn init() -> #(Model, Effect(Msg)) {
  let model = Model(question_id: None, vote: None)
  #(model, effect.none())
}

pub type Msg {
  QuestionIdChanged(String)
  UserIsVoting(String)
  ApiReturnedVote(Result(vote.Vote, rsvp.Error))
  ApiRegisteredVote(Result(vote.Vote, rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    QuestionIdChanged(id) -> #(
      Model(question_id: Some(id), vote: None),
      fetch_vote(id, ApiReturnedVote),
    )

    UserIsVoting(vote) -> {
      echo "voting " <> vote
      case model.question_id {
        None -> #(model, effect.none())
        Some(question_id) -> #(
          model,
          cast_vote(question_id, vote, ApiRegisteredVote),
        )
      }
    }

    ApiReturnedVote(Ok(vote)) -> #(
      Model(..model, vote: Some(vote)),
      effect.none(),
    )
    ApiReturnedVote(Error(_)) -> #(model, effect.none())

    ApiRegisteredVote(Ok(vote)) -> #(
      Model(..model, vote: Some(vote)),
      effect.none(),
    )
    ApiRegisteredVote(Error(_)) -> #(model, effect.none())
  }
}

pub fn view(model: Model) -> Element(Msg) {
  html.div(
    [
      attribute.class("prose"),
      event.on("question-changed", {
        echo "question-changed"
        use id <- decode.then(decode.string)
        decode.success(QuestionIdChanged(id))
      }),
    ],
    [
      html.h1([], [html.text("Live")]),
      server_component.element(
        [
          server_component.route("/ws/live"),
          server_component.method(server_component.WebSocket),
        ],
        [
          case model.question_id, model.vote {
            Some(_id), Some(vote) -> view_registered_vote(vote)
            Some(_id), None -> view_voting_buttons()
            None, _ -> element.none()
          },
        ],
      ),
    ],
  )
}

fn view_registered_vote(vote: vote.Vote) -> Element(msg) {
  html.div([], [
    html.text("You have voted!"),
    html.text(vote.vote |> vote.vote_type_to_string()),
  ])
}

fn view_voting_buttons() -> Element(Msg) {
  html.div([attribute.class("space-x-4")], [
    html.button(
      [
        attribute.id("yes"),
        attribute.class("btn btn-primary btn-sm"),
        event.on_click(UserIsVoting("yes")),
      ],
      [
        html.text("Yes"),
      ],
    ),
    html.button(
      [
        attribute.id("no"),
        attribute.class("btn btn-primary btn-sm"),
      ],
      [
        html.text("No"),
      ],
    ),
    html.button(
      [
        attribute.id("blank"),
        attribute.class("btn btn-primary btn-sm"),
      ],
      [html.text("Abstain")],
    ),
  ])
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
