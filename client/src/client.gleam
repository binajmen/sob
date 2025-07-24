import forms
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import model.{type Model, type Msg}
import modem
import router
import routes/about
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
  let model = model.Base(app: model.App(route: initial_route, lang: "en"))
  let effect =
    modem.init(fn(uri) { uri |> router.parse_route |> model.UserNavigatedTo })

  #(model, effect)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    model.UserNavigatedTo(router.SignIn) -> #(
      model.SignIn(
        app: model.App(..model.app, route: router.SignIn),
        form: forms.sign_in_form(),
      ),
      effect.none(),
    )
    model.UserNavigatedTo(router.SignUp) -> #(
      model.SignUp(
        app: model.App(..model.app, route: router.SignUp),
        form: forms.sign_up_form(),
      ),
      effect.none(),
    )
    model.UserNavigatedTo(route) -> #(
      model.Base(app: model.App(..model.app, route:)),
      effect.none(),
    )
    model.UserSubmittedSignInForm(result) ->
      sign_in.update(model, result) |> echo
    model.UserSubmittedSignUpForm(result) -> sign_up.update(model, result)
    model.ApiAuthenticatedUser(Ok(_)) -> #(
      model.Base(app: model.App(..model.app, route: router.About)),
      effect.none(),
    )
    model.ApiAuthenticatedUser(Error(_)) -> #(
      model.Base(app: model.App(..model.app, route: router.SignIn)),
      effect.none(),
    )
  }
}

fn view(model: Model) -> Element(Msg) {
  case model.app.route {
    router.Index -> index.view()
    router.SignIn -> sign_in.view(forms.sign_in_form())
    router.SignUp -> sign_up.view(forms.sign_up_form())
    router.About -> about.view()
    _ -> view_not_found()
  }
}

fn view_not_found() -> Element(Msg) {
  html.span([], [html.text("not found")])
}
