import formal/form
import forms
import gleam/option.{None, Some}
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import model.{type Model, type Msg}
import modem
import router
import routes/about
import routes/admin/polls
import routes/index
import routes/sign_in
import routes/sign_up
import shared/poll

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", [])

  Nil
}

fn init(_options) -> #(Model, Effect(Msg)) {
  let initial_route = router.initial_route()
  let #(model, route_effect) = case initial_route {
    router.Index -> #(
      model.Base(app: model.App(route: initial_route, lang: "en")),
      effect.none(),
    )
    router.SignIn -> #(
      model.SignIn(
        app: model.App(route: initial_route, lang: "en"),
        form: forms.sign_in_form(),
      ),
      effect.none(),
    )
    router.SignUp -> #(
      model.SignUp(
        app: model.App(route: initial_route, lang: "en"),
        form: forms.sign_up_form(),
      ),
      effect.none(),
    )
    router.AdminPolls -> polls.init(None)
    _ -> #(
      model.Base(app: model.App(route: initial_route, lang: "en")),
      effect.none(),
    )
  }
  let effect =
    effect.batch([
      modem.init(fn(uri) { uri |> router.parse_route |> model.UserNavigatedTo }),
      route_effect,
    ])

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
    model.UserNavigatedTo(router.AdminPolls) -> polls.init(Some(model))
    model.UserNavigatedTo(route) -> #(
      model.Base(app: model.App(..model.app, route:)),
      effect.none(),
    )
    model.UserSubmittedSignInForm(result) -> sign_in.update(model, result)
    model.UserSubmittedSignUpForm(result) -> sign_up.update(model, result)
    model.ApiReturnedPolls(Ok(polls)) -> #(
      model.AdminPolls(app: model.app, polls:),
      effect.none(),
    )
    model.ApiReturnedPolls(Error(_)) -> #(
      model.AdminPolls(
        app: model.App(..model.app, route: router.AdminPolls),
        polls: [],
      ),
      effect.none(),
    )
    model.ApiAuthenticatedUser(Ok(_)) -> polls.init(Some(model))
    // model.ApiAuthenticatedUser(Ok(_)) -> #(
    //   model.Base(app: model.App(..model.app, route: router.AdminPolls)),
    //   effect.none(),
    // )
    model.ApiAuthenticatedUser(Error(_)) -> #(
      model.SignIn(
        app: model.App(..model.app, route: router.SignIn),
        form: forms.sign_in_form()
          |> form.add_error(
            "password",
            form.CustomError("Email or password is incorrect"),
          ),
      ),
      effect.none(),
    )
  }
}

fn view(model: Model) -> Element(Msg) {
  case model.app.route, model {
    router.Index, _ -> index.view()
    router.About, _ -> about.view()
    router.SignIn, model.SignIn(_, form) -> sign_in.view(form)
    router.SignUp, model.SignUp(_, form) -> sign_up.view(form)
    router.AdminPolls, model.AdminPolls(_, polls) -> polls.view(polls)
    router.AdminPolls, model.SignIn(_, _) ->
      polls.view([poll.Poll(id: "1", name: "Sign in model?")])
    router.AdminPolls, _ -> {
      echo model
      polls.view([poll.Poll(id: "1", name: "Wrong model?")])
    }
    _, _ -> view_not_found()
  }
}

fn view_not_found() -> Element(Msg) {
  html.span([], [html.text("not found")])
}
