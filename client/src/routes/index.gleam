import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import model.{type Msg}

pub fn view() -> Element(Msg) {
  html.span([], [
    html.text("index"),
    html.button([attribute.class("btn btn-primary")], [html.text("Click me")]),
  ])
}
