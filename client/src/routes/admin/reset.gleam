import components/admin_nav
import gleam/http/response
import gleam/json
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import rsvp

pub type Model {
  Model(state: State)
}

pub type State {
  Ready
  Confirming
  Resetting
  Success
  Failed
}

pub fn init() -> #(Model, Effect(Msg)) {
  #(Model(state: Ready), effect.none())
}

pub type Msg {
  UserClickedReset
  UserConfirmedReset
  UserCancelledReset
  ApiReturnedResetResult(Result(response.Response(String), rsvp.Error))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserClickedReset -> #(
      Model(state: Confirming),
      effect.none(),
    )
    UserConfirmedReset -> #(
      Model(state: Resetting),
      reset_all_votes(ApiReturnedResetResult),
    )
    UserCancelledReset -> #(
      Model(state: Ready),
      effect.none(),
    )
    ApiReturnedResetResult(Ok(_)) -> #(
      Model(state: Success),
      effect.none(),
    )
    ApiReturnedResetResult(Error(_)) -> #(
      Model(state: Failed),
      effect.none(),
    )
  }
}

pub fn view(model: Model) -> Element(Msg) {
  html.div([], [
    admin_nav.view(),
    html.div([attribute.class("prose max-w-2xl mx-auto")], [
      html.h1([attribute.class("text-center")], [html.text("Reset All Votes")]),
      view_content(model.state),
    ]),
  ])
}

fn view_content(state: State) -> Element(Msg) {
  case state {
    Ready -> view_ready()
    Confirming -> view_confirming()
    Resetting -> view_resetting()
    Success -> view_success()
    Failed -> view_failed()
  }
}

fn view_ready() -> Element(Msg) {
  html.div([attribute.class("text-center space-y-4")], [
    html.div([attribute.class("bg-yellow-50 border border-yellow-200 rounded-lg p-4")], [
      html.h2([attribute.class("text-yellow-800 font-semibold")], [
        html.text("⚠️ Danger Zone"),
      ]),
      html.p([attribute.class("text-yellow-700")], [
        html.text("This action will permanently delete all votes from all questions."),
      ]),
      html.p([attribute.class("text-yellow-700 text-sm")], [
        html.text("This cannot be undone."),
      ]),
    ]),
    html.button(
      [
        attribute.class("btn btn-warning"),
        event.on_click(UserClickedReset),
      ],
      [html.text("🧹 Reset All Votes")],
    ),
  ])
}

fn view_confirming() -> Element(Msg) {
  html.div([attribute.class("text-center space-y-4")], [
    html.div([attribute.class("bg-red-50 border border-red-200 rounded-lg p-4")], [
      html.h2([attribute.class("text-red-800 font-semibold")], [
        html.text("🚨 Final Confirmation"),
      ]),
      html.p([attribute.class("text-red-700 font-medium")], [
        html.text("Are you absolutely sure you want to delete ALL votes?"),
      ]),
      html.p([attribute.class("text-red-600 text-sm")], [
        html.text("This will permanently remove all voting data and cannot be recovered."),
      ]),
    ]),
    html.div([attribute.class("flex gap-4 justify-center")], [
      html.button(
        [
          attribute.class("btn btn-outline"),
          event.on_click(UserCancelledReset),
        ],
        [html.text("Cancel")],
      ),
      html.button(
        [
          attribute.class("btn btn-error"),
          event.on_click(UserConfirmedReset),
        ],
        [html.text("🗑️ Yes, Delete All Votes")],
      ),
    ]),
  ])
}

fn view_resetting() -> Element(Msg) {
  html.div([attribute.class("text-center space-y-4")], [
    html.div([attribute.class("bg-blue-50 border border-blue-200 rounded-lg p-4")], [
      html.h2([attribute.class("text-blue-800 font-semibold")], [
        html.text("🔄 Resetting..."),
      ]),
      html.p([attribute.class("text-blue-700")], [
        html.text("Deleting all votes, please wait..."),
      ]),
    ]),
    html.div([attribute.class("loading loading-spinner loading-lg")], []),
  ])
}

fn view_success() -> Element(Msg) {
  html.div([attribute.class("text-center space-y-4")], [
    html.div([attribute.class("bg-green-50 border border-green-200 rounded-lg p-4")], [
      html.h2([attribute.class("text-green-800 font-semibold")], [
        html.text("✅ Success"),
      ]),
      html.p([attribute.class("text-green-700")], [
        html.text("All votes have been successfully deleted."),
      ]),
    ]),
    html.button(
      [
        attribute.class("btn btn-primary"),
        event.on_click(UserCancelledReset),
      ],
      [html.text("Reset Another Round")],
    ),
  ])
}

fn view_failed() -> Element(Msg) {
  html.div([attribute.class("text-center space-y-4")], [
    html.div([attribute.class("bg-red-50 border border-red-200 rounded-lg p-4")], [
      html.h2([attribute.class("text-red-800 font-semibold")], [
        html.text("❌ Reset Failed"),
      ]),
      html.p([attribute.class("text-red-700")], [
        html.text("There was an error deleting the votes. Please try again."),
      ]),
    ]),
    html.button(
      [
        attribute.class("btn btn-primary"),
        event.on_click(UserCancelledReset),
      ],
      [html.text("Try Again")],
    ),
  ])
}

fn reset_all_votes(
  on_response handle_response: fn(Result(response.Response(String), rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "/api/votes"
  let body = json.null()
  let handler = rsvp.expect_ok_response(handle_response)
  rsvp.delete(url, body, handler)
}