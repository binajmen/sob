import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/server_component

pub type Model {
  Model(id: String)
}

pub fn init(id: String) -> #(Model, Effect(Msg)) {
  let model = Model(id:)
  #(model, effect.none())
}

pub type Msg

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  #(model, effect.none())
}

pub fn view() -> Element(msg) {
  html.div([attribute.class("prose")], [
    html.h1([attribute.class("text-center")], [
      html.text("Sing Out Brussels!"),
    ]),
    server_component.element(
      [
        server_component.route("/ws/live"),
        server_component.method(server_component.WebSocket),
      ],
      [view_controls()],
    ),
  ])
}

fn view_controls() -> Element(msg) {
  html.div([attribute.class("space-x-4")], [
    html.button(
      [attribute.id("waiting"), attribute.class("btn btn-primary btn-sm")],
      [
        html.text("Waiting"),
      ],
    ),
    html.button(
      [attribute.id("next-question"), attribute.class("btn btn-primary btn-sm")],
      [
        html.text("Next question"),
      ],
    ),
    html.button(
      [
        attribute.id("close-voting"),
        attribute.class("btn btn-secondary btn-sm"),
      ],
      [html.text("Close voting")],
    ),
    html.button(
      [attribute.id("finished"), attribute.class("btn btn-primary btn-sm")],
      [
        html.text("Finished"),
      ],
    ),
    html.button(
      [
        attribute.id("reset-votes"),
        attribute.class("btn btn-error btn-sm"),
      ],
      [html.text("Reset Votes")],
    ),
  ])
}
