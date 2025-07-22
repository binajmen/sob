import formal/form
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import model.{type Model, type Msg, Model}
import modem
import router
import routes/index
import routes/sign_in
import routes/sign_up

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", [])

  Nil
}

fn init(_options) -> #(Model, Effect(Msg)) {
  let initial_route = router.initial_route()
  let model =
    Model(
      route: initial_route,
      sign_in_form: form.new(),
      sign_up_form: form.new(),
    )
  let effect =
    modem.init(fn(uri) { uri |> router.parse_route |> model.UserNavigatedTo })

  #(model, effect)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    model.UserNavigatedTo(route:) -> #(Model(..model, route:), effect.none())
    model.UserSubmittedSignInForm(values) -> sign_in.update(model, values)
    model.UserSubmittedSignUpForm(values) -> sign_up.update(model, values)
    model.ApiAuthenticatedUser(Ok(_)) -> #(
      Model(..model, route: router.Index),
      effect.none(),
    )
    model.ApiAuthenticatedUser(Error(_)) -> #(
      Model(..model, route: router.About),
      effect.none(),
    )
  }
}

fn view(model: Model) -> Element(Msg) {
  case model.route {
    router.Index -> index.view()
    router.SignIn -> sign_in.view(model.sign_in_form)
    router.SignUp -> sign_up.view(model.sign_up_form)
    _ -> view_not_found()
  }
}

fn view_not_found() -> Element(Msg) {
  html.span([], [html.text("not found")])
}
