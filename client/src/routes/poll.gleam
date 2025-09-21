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
import shared/vote.{Vote}

pub type Model {
  Model(question_id: Option(String), vote: Option(vote.Vote))
}

pub fn init() -> #(Model, Effect(Msg)) {
  let model = Model(question_id: None, vote: None)
  #(model, fetch_current_question(ApiReturnedCurrentQuestion))
}

pub type Msg {
  NoQuestions
  QuestionIdChanged(String)
  UserIsVoting(String)
  ApiReturnedVote(Result(vote.Vote, rsvp.Error))
  ApiRegisteredVote(Result(vote.Vote, rsvp.Error))
  ApiReturnedCurrentQuestion(Result(Option(String), rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NoQuestions -> #(Model(question_id: None, vote: None), effect.none())

    QuestionIdChanged(id) -> #(
      Model(question_id: Some(id), vote: None),
      fetch_vote(id, ApiReturnedVote),
    )

    UserIsVoting(vote) -> {
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

    ApiReturnedCurrentQuestion(Ok(Some(question_id))) -> #(
      Model(question_id: Some(question_id), vote: None),
      fetch_vote(question_id, ApiReturnedVote),
    )
    ApiReturnedCurrentQuestion(Ok(None)) -> #(model, effect.none())
    ApiReturnedCurrentQuestion(Error(_)) -> #(model, effect.none())
  }
}

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("prose whitespace-pre-wrap")], [
    html.h1([attribute.class("text-center !m-0")], [
      html.text("Sing Out Brussels!"),
    ]),
    html.h2([attribute.class("text-center !m-0")], [
      html.text("The Fabulous Queer Choir"),
    ]),
    server_component.element(
      [
        server_component.route("/ws/live"),
        server_component.method(server_component.WebSocket),
        event.on("next-question", {
          decode.at(["detail"], decode.string)
          |> decode.map(QuestionIdChanged)
        }),
        event.on("no-questions", { decode.success(NoQuestions) }),
      ],
      [
        case model.question_id {
          Some(_id) -> view_voting_buttons(model.vote)
          None -> element.none()
        },
        // view_voting_buttons(),
      ],
    ),
  ])
}

fn view_voting_buttons(vote: Option(vote.Vote)) -> Element(Msg) {
  let current = "border-4 border-black"

  html.div(
    [attribute.class("grid grid-cols-3 gap-4 bg-white p-4 sticky bottom-0")],
    [
      html.button(
        [
          attribute.id("yes"),
          attribute.class(
            "btn btn-primary "
            <> case vote {
              Some(vote) ->
                case vote.vote {
                  vote.Yes -> current
                  _ -> ""
                }
              _ -> ""
            },
          ),
          event.on_click(UserIsVoting("yes")),
        ],
        [
          html.text("Yes"),
        ],
      ),
      html.button(
        [
          attribute.id("no"),
          attribute.class(
            "btn btn-primary "
            <> case vote {
              Some(vote) ->
                case vote.vote {
                  vote.No -> current
                  _ -> ""
                }
              _ -> ""
            },
          ),
          event.on_click(UserIsVoting("no")),
        ],
        [
          html.text("No"),
        ],
      ),
      html.button(
        [
          attribute.id("blank"),
          attribute.class(
            "btn btn-primary "
            <> case vote {
              Some(vote) ->
                case vote.vote {
                  vote.Blank -> current
                  _ -> ""
                }
              _ -> ""
            },
          ),
          event.on_click(UserIsVoting("blank")),
        ],
        [html.text("Abstain")],
      ),
    ],
  )
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

fn fetch_current_question(
  on_response handle_response: fn(Result(Option(String), rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "/api/questions/current"
  let decoder = decode.optional(decode.at(["id"], decode.string))
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}
