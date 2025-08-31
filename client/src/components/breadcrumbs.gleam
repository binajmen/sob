import gleam/list
import gleam/option.{type Option}
import lustre/attribute
import lustre/element/html

pub type Crumb {
  Crumb(label: String, url: Option(String))
}

pub fn view(crumbs: List(Crumb)) {
  html.div([attribute.class("breadcrumbs")], [
    html.ul(
      [],
      list.map(crumbs, fn(crumb) {
        html.li([], [
          case crumb.url {
            option.None -> html.text(crumb.label)
            option.Some(url) ->
              html.a([attribute.href(url)], [html.text(crumb.label)])
          },
        ])
      }),
    ),
  ])
}
