import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(
  is type_: String,
  label label: String,
  class class: String,
  on_click on_click: msg,
) -> Element(msg) {
  html.button(
    [attribute.type_(type_), attribute.class(class), event.on_click(on_click)],
    [html.text(label)],
  )
}

pub fn submit(label label: String) -> Element(msg) {
  html.button([attribute.type_("submit")], [html.text(label)])
}
