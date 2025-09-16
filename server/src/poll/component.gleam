import gleam/int
import lustre.{type App}
import lustre/attribute
import lustre/component
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn component() -> App(_, Model, Msg) {
  lustre.component(init, update, view, [])
}

pub type Model =
  Int

fn init(_) -> #(Model, Effect(Msg)) {
  #(0, effect.none())
}

pub opaque type Msg {
  UserClickedIncrement
  UserClickedDecrement
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserClickedIncrement -> #(model + 1, effect.none())
    UserClickedDecrement -> #(model - 1, effect.none())
  }
}

fn view(model: Model) -> Element(Msg) {
  let count = int.to_string(model)
  let styles = [#("display", "flex"), #("justify-content", "space-between")]

  html.div([], [
    html.h1([], [html.text("Hi")]),
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
