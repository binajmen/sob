import components/breadcrumbs
import gleam/option.{None}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import router

pub fn view() -> Element(msg) {
  html.div([attribute.class("space-y-4")], [
    breadcrumbs.view([breadcrumbs.Crumb("Admin", None)]),
    html.a([router.href(router.AdminPolls)], [
      html.button([attribute.class("btn btn-primary")], [
        html.text("View polls"),
      ]),
    ]),
  ])
}
