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
import shared/user
import shared/vote.{Vote}

pub type Model {
  Model(
    question_id: Option(String), 
    vote: Option(vote.Vote),
    proxy_vote: Option(vote.Vote),
    user: Option(user.User)
  )
}

pub fn init() -> #(Model, Effect(Msg)) {
  let model = Model(question_id: None, vote: None, proxy_vote: None, user: None)
  #(model, effect.batch([
    fetch_current_question(ApiReturnedCurrentQuestion),
    fetch_current_user(ApiReturnedCurrentUser)
  ]))
}

pub type Msg {
  NoQuestions
  QuestionIdChanged(String)
  UserIsVotingForSelf(String)
  UserIsVotingForProxy(String)
  ApiReturnedVote(Result(vote.Vote, rsvp.Error))
  ApiReturnedProxyVote(Result(vote.Vote, rsvp.Error))
  ApiRegisteredVote(Result(vote.Vote, rsvp.Error))
  ApiRegisteredProxyVote(Result(vote.Vote, rsvp.Error))
  ApiReturnedCurrentQuestion(Result(Option(String), rsvp.Error))
  ApiReturnedCurrentUser(Result(user.User, rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NoQuestions -> #(Model(question_id: None, vote: None, proxy_vote: None, user: model.user), effect.none())

    QuestionIdChanged(id) -> #(
      Model(..model, question_id: Some(id), vote: None, proxy_vote: None),
      fetch_vote(id, ApiReturnedVote)
    )

    UserIsVotingForSelf(vote) -> {
      case model.question_id {
        None -> #(model, effect.none())
        Some(question_id) -> #(
          model,
          cast_vote_for_self(question_id, vote, ApiRegisteredVote),
        )
      }
    }

    UserIsVotingForProxy(vote) -> {
      case model.question_id, model.user {
        Some(question_id), Some(user) -> {
          case user.proxy_id {
            Some(proxy_id) -> #(
              model,
              cast_vote_for_proxy(question_id, vote, proxy_id, ApiRegisteredProxyVote),
            )
            None -> #(model, effect.none())
          }
        }
        _, _ -> #(model, effect.none())
      }
    }

    ApiReturnedVote(Ok(vote)) -> #(
      Model(..model, vote: Some(vote)),
      effect.none(),
    )
    ApiReturnedVote(Error(_)) -> #(model, effect.none())

    ApiReturnedProxyVote(Ok(vote)) -> #(
      Model(..model, proxy_vote: Some(vote)),
      effect.none(),
    )
    ApiReturnedProxyVote(Error(_)) -> #(model, effect.none())

    ApiRegisteredVote(Ok(vote)) -> #(
      Model(..model, vote: Some(vote)),
      effect.none(),
    )
    ApiRegisteredVote(Error(_)) -> #(model, effect.none())

    ApiRegisteredProxyVote(Ok(vote)) -> #(
      Model(..model, proxy_vote: Some(vote)),
      effect.none(),
    )
    ApiRegisteredProxyVote(Error(_)) -> #(model, effect.none())

    ApiReturnedCurrentQuestion(Ok(Some(question_id))) -> #(
      Model(..model, question_id: Some(question_id), vote: None, proxy_vote: None),
      fetch_vote(question_id, ApiReturnedVote)
    )
    ApiReturnedCurrentQuestion(Ok(None)) -> #(model, effect.none())
    ApiReturnedCurrentQuestion(Error(_)) -> #(model, effect.none())

    ApiReturnedCurrentUser(Ok(user)) -> #(
      Model(..model, user: Some(user)),
      effect.none(),
    )
    ApiReturnedCurrentUser(Error(_)) -> #(model, effect.none())
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
        case model.question_id, model.user {
          Some(_id), Some(user) -> view_voting_interface(user, model.vote, model.proxy_vote)
          _, _ -> element.none()
        },
        // view_voting_buttons(),
      ],
    ),
  ])
}

fn view_voting_interface(user: user.User, vote: Option(vote.Vote), proxy_vote: Option(vote.Vote)) -> Element(Msg) {
  case user.proxy_id {
    Some(_) -> {
      html.div([attribute.class("bg-white p-4 sticky bottom-0")], [
        html.div([attribute.class("mb-4")], [
          html.h3([attribute.class("text-lg font-semibold mb-2")], [
            html.text("Your Vote:")
          ]),
          view_voting_buttons(vote, UserIsVotingForSelf)
        ]),
        html.div([], [
          html.h3([attribute.class("text-lg font-semibold mb-2")], [
            html.text("Proxy Vote:")
          ]),
          view_voting_buttons(proxy_vote, UserIsVotingForProxy)
        ])
      ])
    }
    None -> html.div([attribute.class("bg-white p-4 sticky bottom-0")], [
      view_voting_buttons(vote, UserIsVotingForSelf)
    ])
  }
}

fn view_voting_buttons(vote: Option(vote.Vote), vote_handler: fn(String) -> Msg) -> Element(Msg) {
  let current = "border-4 border-black"

  html.div(
    [attribute.class("grid grid-cols-3 gap-4")],
    [
      html.button(
        [
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
          event.on_click(vote_handler("yes")),
        ],
        [
          html.text("Yes"),
        ],
      ),
      html.button(
        [
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
          event.on_click(vote_handler("no")),
        ],
        [
          html.text("No"),
        ],
      ),
      html.button(
        [
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
          event.on_click(vote_handler("blank")),
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

fn cast_vote_for_self(
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

fn cast_vote_for_proxy(
  question_id: String,
  vote: String,
  proxy_id: String,
  on_response handle_response: fn(Result(vote.Vote, rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "/api/votes"
  let body =
    json.object([
      #("question_id", json.string(question_id)),
      #("vote", json.string(vote)),
      #("voting_for_user_id", json.string(proxy_id)),
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

fn fetch_current_user(
  on_response handle_response: fn(Result(user.User, rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "/api/auth/me"
  let decoder = user.user_decoder()
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}


