import components/breadcrumbs
import gleam/dynamic/decode
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import router
import rsvp
import shared/poll.{type Poll}
import shared/question.{type Question}

pub type Model {
  Model(poll: Option(Poll), questions: List(Question))
}

pub fn init(poll_id: String) -> #(Model, Effect(Msg)) {
  let model = Model(poll: None, questions: [])
  #(
    model,
    effect.batch([
      fetch_poll(poll_id, ApiReturnedPoll),
      fetch_questions(poll_id, ApiReturnedQuestions),
    ]),
  )
}

pub type Msg {
  ApiReturnedPoll(Result(Poll, rsvp.Error))
  ApiReturnedQuestions(Result(List(Question), rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ApiReturnedPoll(Ok(poll)) -> #(
      Model(..model, poll: Some(poll)),
      effect.none(),
    )
    ApiReturnedPoll(Error(error)) -> {
      echo error
      #(model, effect.none())
    }
    ApiReturnedQuestions(Ok(questions)) -> #(
      Model(..model, questions: questions),
      effect.none(),
    )
    ApiReturnedQuestions(Error(error)) -> {
      echo error
      #(model, effect.none())
    }
  }
}

pub fn view(poll: Option(Poll), questions: List(Question)) -> Element(Msg) {
  case poll {
    None -> html.div([], [html.text("Loading..")])
    Some(poll) ->
      html.div([attribute.class("space-y-4")], [
        breadcrumbs.view([
          breadcrumbs.Crumb("Admin", Some(router.to_path(router.Admin))),
          breadcrumbs.Crumb("Polls", Some(router.to_path(router.AdminPolls))),
          breadcrumbs.Crumb(
            poll.name,
            Some(router.to_path(router.AdminPollsView(poll.id))),
          ),
          breadcrumbs.Crumb("Questions", None),
        ]),
        html.div([attribute.class("prose flex justify-between items-start")], [
          html.h1([], [html.text("Questions")]),
          html.a([router.href(router.AdminQuestionsCreate(poll.id))], [
            html.button([attribute.class("btn btn-primary")], [
              html.text("Create question"),
            ]),
          ]),
        ]),
        html.table([attribute.class("table table-zebra w-auto")], [
          html.thead([], [
            html.tr([], [
              html.th([], []),
              html.th([], [html.text("Prompt")]),
              html.th([], []),
            ]),
          ]),
          html.tbody(
            [],
            list.map(questions, fn(question) {
              html.tr([], [
                html.th([], [html.text(question.id)]),
                html.td([], [html.text(question.prompt)]),
                html.td([], [
                  html.a(
                    [
                      router.href(router.AdminQuestionsView(
                        poll.id,
                        question.id,
                      )),
                    ],
                    [
                      html.button([attribute.class("btn btn-primary btn-sm")], [
                        html.text("View"),
                      ]),
                    ],
                  ),
                ]),
              ])
            }),
          ),
        ]),
      ])
  }
}

fn fetch_poll(
  id: String,
  on_response handle_response: fn(Result(Poll, rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "http://localhost:3000/api/polls/" <> id
  let handler = rsvp.expect_json(poll.poll_decoder(), handle_response)

  rsvp.get(url, handler)
}

fn fetch_questions(
  poll_id: String,
  on_response handle_response: fn(Result(List(Question), rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "http://localhost:3000/api/polls/" <> poll_id <> "/questions"
  let decoder =
    decode.list(question.question_decoder()) |> decode.map(list.take(_, 10))
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}
