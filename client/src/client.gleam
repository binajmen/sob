import formal/form
import gleam/option.{None}
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import model.{type Model, type Msg, Model}
import modem
import router
import routes/index
import routes/login

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", [])

  Nil
}

fn init(_options) -> #(Model, Effect(Msg)) {
  let initial_route = router.initial_route()
  let model = Model(route: initial_route, user_id: None, login_form: form.new())
  let effect =
    modem.init(fn(uri) { uri |> router.parse_route |> model.UserNavigatedTo })

  #(model, effect)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    model.UserNavigatedTo(route:) -> #(Model(..model, route:), effect.none())
    model.UserSubmittedLoginForm(values) -> login.update(model, values)
  }
}

fn view(model: Model) -> Element(Msg) {
  case model.route {
    router.Index -> index.view()
    router.Login -> login.view(model.login_form)
    _ -> view_not_found()
  }
}

fn view_not_found() -> Element(Msg) {
  html.span([], [html.text("not found")])
}
