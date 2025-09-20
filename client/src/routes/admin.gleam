import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import router

pub fn view() -> Element(msg) {
  html.div([attribute.class("space-y-4")], [
    html.a([router.href(router.AdminQuestionsList)], [
      html.button([attribute.class("btn btn-primary")], [
        html.text("Questions"),
      ]),
    ]),
    html.a([router.href(router.AdminLive)], [
      html.button([attribute.class("btn btn-primary")], [
        html.text("Live"),
      ]),
    ]),
  ])
}
