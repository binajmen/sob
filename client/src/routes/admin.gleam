import components/breadcrumbs
import gleam/option.{Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import router

pub fn view() -> Element(msg) {
  html.div([], [
    breadcrumbs.view([
      breadcrumbs.Crumb("Admin", Some(router.to_path(router.Admin))),
    ]),
    html.a([router.href(router.AdminPolls)], [
      html.button([attribute.class("btn btn-primary")], [
        html.text("View polls"),
      ]),
    ]),
  ])
}
