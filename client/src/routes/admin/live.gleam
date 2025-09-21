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

pub fn update(model: Model, _msg: Msg) -> #(Model, Effect(Msg)) {
  #(model, effect.none())
}

pub fn view() -> Element(msg) {
  html.div(
    [
      attribute.class("prose"),
    ],
    [
      html.h1([attribute.class("text-center !m-0")], [
        html.text("Sing Out Brussels!"),
      ]),
      html.h2([attribute.class("text-center !m-0")], [
        html.text("The Fabulous Queer Choir"),
      ]),
      server_component.element(
        [
          server_component.route("/ws/live"),
          server_component.method(server_component.WebSocket),
        ],
        [view_controls()],
      ),
    ],
  )
}

fn view_controls() -> Element(msg) {
  html.div([attribute.class("space-x-4")], [
    html.button(
      [attribute.id("waiting"), attribute.class("btn btn-primary btn-sm")],
      [
        html.text("⏱️ Waiting"),
      ],
    ),
    html.button(
      [attribute.id("next-question"), attribute.class("btn btn-primary btn-sm")],
      [
        html.text("❓ Next question"),
      ],
    ),
    html.button(
      [
        attribute.id("close-voting"),
        attribute.class("btn btn-primary btn-sm"),
      ],
      [html.text("🛑 Close voting")],
    ),
    html.button(
      [attribute.id("finished"), attribute.class("btn btn-primary btn-sm")],
      [
        html.text("🎬 End"),
      ],
    ),
    html.button(
      [
        attribute.id("reset-votes"),
        attribute.class("btn btn-primary btn-sm"),
      ],
      [html.text("🧹 Reset")],
    ),
  ])
}
