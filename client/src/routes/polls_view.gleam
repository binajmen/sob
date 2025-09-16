import config
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

pub fn view(id: String) -> Element(msg) {
  html.div([attribute.class("card")], [
    html.text("Poll"),
    server_component.script(),
    server_component.element(
      [
        server_component.route(config.base_url() <> "/ws/poll/" <> id),
        server_component.method(server_component.WebSocket),
      ],
      [],
    ),
  ])
}
