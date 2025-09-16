import components/breadcrumbs
import components/input
import formal/form.{type Form}
import gleam/json
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import router
import rsvp
import shared/poll.{type Poll}

pub type Model {
  Model(poll: Option(Poll), form: Form(UpdatePollData))
}

pub type UpdatePollData {
  UpdatePollData(id: String, name: String)
}

pub fn update_poll_form() -> Form(UpdatePollData) {
  form.new({
    use id <- form.field("id", form.parse_string)
    use name <- form.field("name", form.parse_string)
    form.success(UpdatePollData(id:, name:))
  })
}

pub fn init(id: String) -> #(Model, Effect(Msg)) {
  let model = Model(poll: None, form: update_poll_form())
  #(model, fetch_poll(id, ApiReturnedPoll))
}

pub type Msg {
  UserSubmittedForm(Result(UpdatePollData, Form(UpdatePollData)))
  ApiPollUpdated(Result(Poll, rsvp.Error))
  ApiReturnedPoll(Result(Poll, rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserSubmittedForm(result) ->
      case result {
        Ok(poll) -> #(model, update_poll(poll, ApiPollUpdated))
        Error(form) -> #(Model(..model, form:), effect.none())
      }
    ApiPollUpdated(Ok(poll)) -> #(
      Model(..model, poll: Some(poll)),
      effect.none(),
    )
    ApiPollUpdated(Error(_)) -> #(model, effect.none())
    ApiReturnedPoll(Ok(poll)) -> #(
      Model(..model, poll: Some(poll)),
      effect.none(),
    )
    ApiReturnedPoll(Error(_)) -> #(model, effect.none())
  }
}

pub fn view(poll: Option(Poll), form: Form(UpdatePollData)) -> Element(Msg) {
  let submit = fn(fields) {
    form
    |> form.add_values(fields)
    |> form.run
    |> UserSubmittedForm
  }

  case poll {
    None -> html.text("loading..")
    Some(poll) ->
      html.div([attribute.class("space-y-4")], [
        breadcrumbs.view([
          breadcrumbs.Crumb("Admin", Some(router.to_path(router.Admin))),
          breadcrumbs.Crumb("Polls", Some(router.to_path(router.AdminPolls))),
          breadcrumbs.Crumb(poll.name, None),
        ]),
        html.div([attribute.class("prose flex justify-between items-start")], [
          html.h1([], [html.text("Update poll")]),
          html.a([router.href(router.AdminQuestions(poll.id))], [
            html.button([attribute.class("btn btn-primary")], [
              html.text("Manage questions"),
            ]),
          ]),
        ]),
        html.form([event.on_submit(submit), attribute.class("space-y-2")], [
          html.input([
            attribute.type_("hidden"),
            attribute.name("id"),
            attribute.value(poll.id),
          ]),
          input.view(form, "text", "name", "Name", Some(poll.name)),
          html.button(
            [attribute.type_("submit"), attribute.class("btn btn-primary")],
            [html.text("Update poll")],
          ),
        ]),
      ])
  }
}

fn fetch_poll(
  id: String,
  on_response handle_response: fn(Result(Poll, rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "/api/polls/" <> id
  let handler = rsvp.expect_json(poll.poll_decoder(), handle_response)

  rsvp.get(url, handler)
}

fn update_poll(
  poll: UpdatePollData,
  on_response handle_response: fn(Result(Poll, rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "/api/polls/" <> poll.id
  let body =
    json.object([
      #("name", json.string(poll.name)),
    ])
  let handler = rsvp.expect_json(poll.poll_decoder(), handle_response)

  rsvp.patch(url, body, handler)
}
