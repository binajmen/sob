import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import router

pub fn view() -> Element(msg) {
  html.div([attribute.class("card")], [
    html.text("index"),
    html.a([router.href(router.SignIn)], [html.text("Sign In")]),
  ])
}
