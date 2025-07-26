import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import modem
import router.{type Route}
import routes/index
import routes/sign_in

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", [])

  Nil
}

pub type Model {
  Model(route: Route, lang: String, page: Page)
}

pub type Page {
  Index
  SignIn(sign_in.Model)
}

pub type Msg {
  UserNavigatedTo(route: Route)
  SignInMsg(sign_in.Msg)
}

fn init(_options) -> #(Model, Effect(Msg)) {
  let route = router.initial_route()
  let model = Model(route: route, lang: "en", page: Index)
  let #(model, page_effect) = init_route(route, model)
  let effect =
    effect.batch([
      modem.init(fn(uri) {
        uri |> router.parse_route |> UserNavigatedTo |> echo
      }),
      page_effect,
    ])

  #(model, effect)
}

fn init_route(route: Route, model: Model) -> #(Model, Effect(Msg)) {
  case route {
    router.Index -> #(Model(..model, route:, page: Index), effect.none())
    router.SignIn -> {
      let #(page_model, effect) = sign_in.init()
      #(
        Model(..model, route:, page: SignIn(page_model)),
        effect.map(effect, fn(msg) { SignInMsg(msg) }),
      )
    }
    _ -> #(model, effect.none())
  }
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserNavigatedTo(route) -> init_route(route, model) |> echo
    SignInMsg(msg) -> {
      echo msg
      let assert SignIn(page_model) = model.page
      let #(page_model, effect) = sign_in.update(page_model, msg)
      #(
        Model(..model, page: SignIn(page_model)),
        effect.map(effect, fn(msg) { SignInMsg(msg) }),
      )
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  case model.route, model.page {
    router.Index, Index -> index.view()
    router.SignIn, SignIn(sign_in_model) ->
      sign_in.view(sign_in_model.form)
      |> element.map(fn(msg) { SignInMsg(msg) })
    _, _ -> view_not_found()
  }
}

fn view_not_found() -> Element(Msg) {
  html.span([], [html.text("not found")])
}
