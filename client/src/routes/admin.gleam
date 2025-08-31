import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import router

pub fn view() -> Element(msg) {
  html.div([attribute.class("card")], [
    html.a([router.href(router.AdminPolls)], [
      html.button([attribute.class("btn btn-primary")], [
        html.text("View polls"),
      ]),
    ]),
  ])
}
