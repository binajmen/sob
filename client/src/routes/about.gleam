import lustre/element.{type Element}
import lustre/element/html
import model.{type Msg}

pub fn view() -> Element(Msg) {
  html.span([], [html.text("about")])
}
