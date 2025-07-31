import gleam/int
import lustre.{type App}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn component() -> App(_, Model, Msg) {
  lustre.simple(init, update, view)
}

pub type Model =
  Int

fn init(_) -> Model {
  0
}

pub opaque type Msg {
  UserClickedIncrement
  UserClickedDecrement
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    UserClickedIncrement -> model + 1
    UserClickedDecrement -> model - 1
  }
}

fn view(model: Model) -> Element(Msg) {
  let count = int.to_string(model)
  let styles = [#("display", "flex"), #("justify-content", "space-between")]

  element.fragment([
    html.h1([], [html.text("Hi")]),
    html.div([attribute.styles(styles)], [
      view_button(label: "-", on_click: UserClickedDecrement),
      html.p([], [html.text("Count: "), html.text(count)]),
      view_button(label: "+", on_click: UserClickedIncrement),
    ]),
  ])
}

fn view_button(label label: String, on_click handle_click: msg) -> Element(msg) {
  html.button([event.on_click(handle_click)], [html.text(label)])
}
