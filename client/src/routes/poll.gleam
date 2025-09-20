import components/voting_buttons
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/server_component
import shared/vote

pub type Model {
  Model(question_id: Option(String), vote: Option(vote.Vote))
}

pub fn init() -> #(Model, Effect(Msg)) {
  let model = Model(question_id: None, vote: None)
  #(model, effect.none())
}

pub type Msg

pub fn update(model: Model, _msg: Msg) -> #(Model, Effect(Msg)) {
  #(model, effect.none())
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
          None -> voting_buttons.element([], [])
        },
      ],
    ),
  ])
}

fn view_registered_vote(vote: vote.Vote) -> Element(msg) {
  html.div([], [
    html.text("You have voted!"),
    html.text(vote.vote |> vote.vote_type_to_string()),
  ])
}
