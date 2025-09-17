import gleam/int
import lustre.{type App}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn component() -> App(_, Model, Msg) {
  lustre.component(init, update, view, [])
}

pub type Model {
  Model(count: Int, connected_users: Int)
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Model(count: 0, connected_users: 0), effect.none())
}

pub type Msg {
  UserClickedIncrement
  UserClickedDecrement
  UserConnected
  UserDisconnected
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserClickedIncrement -> #(
      Model(..model, count: model.count + 1),
      effect.none(),
    )
    UserClickedDecrement -> #(
      Model(..model, count: model.count - 1),
      effect.none(),
    )
    UserConnected -> #(
      Model(..model, connected_users: model.connected_users + 1),
      effect.none(),
    )
    UserDisconnected -> #(
      Model(..model, connected_users: model.connected_users - 1),
      effect.none(),
    )
  }
}

fn view(model: Model) -> Element(Msg) {
  let count = int.to_string(model.count)
  let connected_users = int.to_string(model.connected_users)
  let styles = [#("display", "flex"), #("justify-content", "space-between")]

  html.div([], [
    html.h1([], [html.text("Poll")]),
    html.div([attribute.class("mb-4")], [
      html.p([attribute.class("text-sm text-gray-500")], [
        html.text("Connected users: "),
        html.text(connected_users),
      ]),
    ]),
    html.div([attribute.styles(styles)], [
      html.button(
        [
          attribute.class("btn btn-primary"),
          event.on_click(UserClickedDecrement),
        ],
        [
          html.text("-"),
        ],
      ),
      html.p([], [html.text("Count: "), html.text(count)]),
      html.button(
        [
          attribute.class("btn btn-primary"),
          event.on_click(UserClickedIncrement),
        ],
        [
          html.text("+"),
        ],
      ),
    ]),
  ])
}
