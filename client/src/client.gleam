import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import modem
import router.{type Route}
import routes/admin/create_poll
import routes/admin/list_polls
import routes/index
import routes/poll
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
  Poll(poll.Model)
  AdminPolls(list_polls.Model)
  AdminPollsCreate(create_poll.Model)
}

pub type Msg {
  UserNavigatedTo(route: Route)
  SignInMsg(sign_in.Msg)
  PollMsg(poll.Msg)
  AdminPollsMsg(list_polls.Msg)
  AdminPollsCreateMsg(create_poll.Msg)
}

fn init(_options) -> #(Model, Effect(Msg)) {
  let route = router.initial_route()
  let model = Model(route: route, lang: "en", page: Index)
  let #(model, page_effect) = init_route(route, model)
  let effect =
    effect.batch([
      modem.init(fn(uri) { uri |> router.parse_route |> UserNavigatedTo }),
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
    router.Poll(id) -> {
      let #(page_model, effect) = poll.init(id)
      #(
        Model(..model, route:, page: Poll(page_model)),
        effect.map(effect, fn(msg) { PollMsg(msg) }),
      )
    }
    router.AdminPolls -> {
      let #(page_model, effect) = list_polls.init()
      #(
        Model(..model, route:, page: AdminPolls(page_model)),
        effect.map(effect, fn(msg) { AdminPollsMsg(msg) }),
      )
    }
    router.AdminPollsCreate -> {
      let #(page_model, effect) = create_poll.init()
      #(
        Model(..model, route:, page: AdminPollsCreate(page_model)),
        effect.map(effect, fn(msg) { AdminPollsCreateMsg(msg) }),
      )
    }
    _ -> #(model, effect.none())
  }
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserNavigatedTo(route) -> init_route(route, model)
    SignInMsg(msg) -> {
      let assert SignIn(page_model) = model.page
      let #(page_model, effect) = sign_in.update(page_model, msg)
      #(
        Model(..model, page: SignIn(page_model)),
        effect.map(effect, fn(msg) { SignInMsg(msg) }),
      )
    }
    PollMsg(msg) -> {
      let assert Poll(page_model) = model.page
      let #(page_model, effect) = poll.update(page_model, msg)
      #(
        Model(..model, page: Poll(page_model)),
        effect.map(effect, fn(msg) { PollMsg(msg) }),
      )
    }
    AdminPollsMsg(msg) -> {
      let assert AdminPolls(page_model) = model.page
      let #(page_model, effect) = list_polls.update(page_model, msg)
      #(
        Model(..model, page: AdminPolls(page_model)),
        effect.map(effect, fn(msg) { AdminPollsMsg(msg) }),
      )
    }
    AdminPollsCreateMsg(msg) -> {
      let assert AdminPollsCreate(page_model) = model.page
      let #(page_model, effect) = create_poll.update(page_model, msg)
      #(
        Model(..model, page: AdminPollsCreate(page_model)),
        effect.map(effect, fn(msg) { AdminPollsCreateMsg(msg) }),
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
    router.Poll(id), Poll(poll_model) ->
      poll.view(poll_model.id)
      |> element.map(fn(msg) { PollMsg(msg) })
    router.AdminPolls, AdminPolls(list_polls_model) ->
      list_polls.view(list_polls_model.polls)
      |> element.map(fn(msg) { AdminPollsMsg(msg) })
    router.AdminPollsCreate, AdminPollsCreate(create_poll_model) ->
      create_poll.view(create_poll_model.form)
      |> element.map(fn(msg) { AdminPollsCreateMsg(msg) })
    _, _ -> view_not_found()
  }
}

fn view_not_found() -> Element(Msg) {
  html.span([], [html.text("not found")])
}
