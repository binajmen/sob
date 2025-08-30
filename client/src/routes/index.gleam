import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/server_component
import router

pub fn view() -> Element(msg) {
  html.div([attribute.class("card")], [
    html.text("index"),
    html.a([router.href(router.SignIn)], [html.text("Sign In")]),
    server_component.script(),
    server_component.element(
      [
        server_component.route("http://localhost:3000/ws"),
        server_component.method(server_component.WebSocket),
      ],
      [],
    ),
  ])
}
