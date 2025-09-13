import components/breadcrumbs
import gleam/dynamic/decode
import gleam/http/response.{type Response}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import plinth/browser/window
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
  UserClickedDelete(String)
  UserConfirmedDelete(String)
  ApiReturnedPoll(Result(Poll, rsvp.Error))
  ApiReturnedQuestions(Result(List(Question), rsvp.Error))
  ApiDeletedQuestion(Result(Response(String), rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserClickedDelete(question_id) -> #(model, confirm_delete(question_id))
    UserConfirmedDelete(question_id) -> #(
      model,
      delete_question(question_id, ApiDeletedQuestion),
    )
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
    ApiDeletedQuestion(_) -> {
      case model.poll {
        Some(poll) -> #(model, fetch_questions(poll.id, ApiReturnedQuestions))
        None -> #(model, effect.none())
      }
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
              html.th([], [html.text("Prompt")]),
              html.th([], []),
            ]),
          ]),
          html.tbody(
            [],
            list.map(questions, fn(question) {
              html.tr([], [
                html.td([], [html.text(question.prompt)]),
                html.td([attribute.class("space-x-2 whitespace-nowrap")], [
                  html.a(
                    [
                      router.href(router.AdminQuestionsView(
                        poll.id,
                        question.id,
                      )),
                    ],
                    [
                      html.button([attribute.class("btn btn-primary btn-sm")], [
                        html.text("Edit"),
                      ]),
                    ],
                  ),
                  html.button(
                    [
                      attribute.class("btn btn-error btn-sm"),
                      event.on_click(UserClickedDelete(question.id)),
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
  let decoder = decode.list(question.question_decoder())
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}

fn confirm_delete(question_id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    case window.confirm("Are you sure you want to delete this question?") {
      True -> dispatch(UserConfirmedDelete(question_id))
      False -> Nil
    }
  })
}

fn delete_question(
  question_id: String,
  on_response handle_response: fn(Result(Response(String), rsvp.Error)) -> Msg,
) -> Effect(Msg) {
  let url = "http://localhost:3000/api/questions/" <> question_id
  let body = json.null()
  let handler = rsvp.expect_ok_response(handle_response)
  rsvp.delete(url, body, handler)
}
