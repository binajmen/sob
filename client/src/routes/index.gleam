import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import model.{type Msg}
import router

pub fn view() -> Element(Msg) {
  html.div([attribute.class("card")], [
    html.text("index"),
    html.a([router.href(router.SignIn)], [html.text("Sign In")]),
    html.a([router.href(router.About)], [html.text("About")]),
    html.a([router.href(router.AdminPolls)], [html.text("Admin Polls")]),
  ])
}
