import gleam/option.{None}
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import modem
import router.{type Route}
import routes/admin
import routes/admin_polls_create
import routes/admin_polls_list
import routes/admin_polls_questions
import routes/admin_polls_questions_create
import routes/guest
import routes/index
import routes/polls_list
import routes/polls_view
import routes/sign_in
import routes/sign_up

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
  SignUp(sign_up.Model)
  Guest(guest.Model)
  Polls(polls_list.Model)
  PollsView(polls_view.Model)
  Admin
  AdminPolls(admin_polls_list.Model)
  AdminPollsCreate(admin_polls_create.Model)
  AdminPollsQuestions(admin_polls_questions.Model)
  AdminPollsQuestionsCreate(admin_polls_questions_create.Model)
}

pub type Msg {
  UserNavigatedTo(route: Route)
  SignInMsg(sign_in.Msg)
  SignUpMsg(sign_up.Msg)
  GuestMsg(guest.Msg)
  PollsMsg(polls_list.Msg)
  PollsViewMsg(polls_view.Msg)
  AdminPollsMsg(admin_polls_list.Msg)
  AdminPollsCreateMsg(admin_polls_create.Msg)
  AdminPollsQuestionsMsg(admin_polls_questions.Msg)
  AdminPollsQuestionsCreateMsg(admin_polls_questions_create.Msg)
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
    router.SignUp -> {
      let #(page_model, effect) = sign_up.init()
      #(
        Model(..model, route:, page: SignUp(page_model)),
        effect.map(effect, fn(msg) { SignUpMsg(msg) }),
      )
    }
    router.Guest -> {
      let #(page_model, effect) = guest.init()
      #(
        Model(..model, route:, page: Guest(page_model)),
        effect.map(effect, fn(msg) { GuestMsg(msg) }),
      )
    }
    router.Polls -> {
      let #(page_model, effect) = polls_list.init()
      #(
        Model(..model, route:, page: Polls(page_model)),
        effect.map(effect, fn(msg) { PollsMsg(msg) }),
      )
    }
    router.PollsView(id) -> {
      let #(page_model, effect) = polls_view.init(id)
      #(
        Model(..model, route:, page: PollsView(page_model)),
        effect.map(effect, fn(msg) { PollsViewMsg(msg) }),
      )
    }
    router.Admin -> #(Model(..model, route:, page: Admin), effect.none())
    router.AdminPolls -> {
      let #(page_model, effect) = admin_polls_list.init()
      #(
        Model(..model, route:, page: AdminPolls(page_model)),
        effect.map(effect, fn(msg) { AdminPollsMsg(msg) }),
      )
    }
    router.AdminPollsCreate -> {
      let #(page_model, effect) = admin_polls_create.init()
      #(
        Model(..model, route:, page: AdminPollsCreate(page_model)),
        effect.map(effect, fn(msg) { AdminPollsCreateMsg(msg) }),
      )
    }
    router.AdminPollsQuestions(id) -> {
      let #(page_model, effect) = admin_polls_questions.init(id)
      #(
        Model(..model, route:, page: AdminPollsQuestions(page_model)),
        effect.map(effect, fn(msg) { AdminPollsQuestionsMsg(msg) }),
      )
    }
    router.AdminPollsQuestionsCreate(id) -> {
      let #(page_model, effect) = admin_polls_questions_create.init(id)
      #(
        Model(..model, route:, page: AdminPollsQuestionsCreate(page_model)),
        effect.map(effect, fn(msg) { AdminPollsQuestionsCreateMsg(msg) }),
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
    SignUpMsg(msg) -> {
      let assert SignUp(page_model) = model.page
      let #(page_model, effect) = sign_up.update(page_model, msg)
      #(
        Model(..model, page: SignUp(page_model)),
        effect.map(effect, fn(msg) { SignUpMsg(msg) }),
      )
    }
    GuestMsg(msg) -> {
      let assert Guest(page_model) = model.page
      let #(page_model, effect) = guest.update(page_model, msg)
      #(
        Model(..model, page: Guest(page_model)),
        effect.map(effect, fn(msg) { GuestMsg(msg) }),
      )
    }
    PollsMsg(msg) -> {
      let assert Polls(page_model) = model.page
      let #(page_model, effect) = polls_list.update(page_model, msg)
      #(
        Model(..model, page: Polls(page_model)),
        effect.map(effect, fn(msg) { PollsMsg(msg) }),
      )
    }
    PollsViewMsg(msg) -> {
      let assert PollsView(page_model) = model.page
      let #(page_model, effect) = polls_view.update(page_model, msg)
      #(
        Model(..model, page: PollsView(page_model)),
        effect.map(effect, fn(msg) { PollsViewMsg(msg) }),
      )
    }
    AdminPollsMsg(msg) -> {
      let assert AdminPolls(page_model) = model.page
      let #(page_model, effect) = admin_polls_list.update(page_model, msg)
      #(
        Model(..model, page: AdminPolls(page_model)),
        effect.map(effect, fn(msg) { AdminPollsMsg(msg) }),
      )
    }
    AdminPollsCreateMsg(msg) -> {
      let assert AdminPollsCreate(page_model) = model.page
      let #(page_model, effect) = admin_polls_create.update(page_model, msg)
      #(
        Model(..model, page: AdminPollsCreate(page_model)),
        effect.map(effect, fn(msg) { AdminPollsCreateMsg(msg) }),
      )
    }
    AdminPollsQuestionsMsg(msg) -> {
      let assert AdminPollsQuestions(page_model) = model.page
      let #(page_model, effect) = admin_polls_questions.update(page_model, msg)
      #(
        Model(..model, page: AdminPollsQuestions(page_model)),
        effect.map(effect, fn(msg) { AdminPollsQuestionsMsg(msg) }),
      )
    }
    AdminPollsQuestionsCreateMsg(msg) -> {
      let assert AdminPollsQuestionsCreate(page_model) = model.page
      let #(page_model, effect) =
        admin_polls_questions_create.update(page_model, msg)
      #(
        Model(..model, page: AdminPollsQuestionsCreate(page_model)),
        effect.map(effect, fn(msg) { AdminPollsQuestionsCreateMsg(msg) }),
      )
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  case model.route, model.page {
    router.Index, Index -> index.view()
    router.SignIn, SignIn(model) ->
      sign_in.view(model.form)
      |> element.map(fn(msg) { SignInMsg(msg) })
    router.SignUp, SignUp(model) ->
      sign_up.view(model.form)
      |> element.map(fn(msg) { SignUpMsg(msg) })
    router.Guest, Guest(model) ->
      guest.view(model.form)
      |> element.map(fn(msg) { GuestMsg(msg) })
    router.Polls, Polls(model) ->
      polls_list.view(model.polls)
      |> element.map(fn(msg) { PollsMsg(msg) })
    router.PollsView(id), PollsView(_model) ->
      polls_view.view(id)
      |> element.map(fn(msg) { PollsViewMsg(msg) })
    router.Admin, Admin -> admin.view()
    router.AdminPolls, AdminPolls(model) ->
      admin_polls_list.view(model.polls)
      |> element.map(fn(msg) { AdminPollsMsg(msg) })
    router.AdminPollsCreate, AdminPollsCreate(model) ->
      admin_polls_create.view(model.form)
      |> element.map(fn(msg) { AdminPollsCreateMsg(msg) })
    router.AdminPollsQuestions(poll_id), AdminPollsQuestions(model) ->
      admin_polls_questions.view(poll_id, model.questions)
      |> element.map(fn(msg) { AdminPollsQuestionsMsg(msg) })
    router.AdminPollsQuestionsCreate(_id), AdminPollsQuestionsCreate(model) ->
      admin_polls_questions_create.view(model.poll, model.form)
      |> element.map(fn(msg) { AdminPollsQuestionsCreateMsg(msg) })
    _, _ -> view_not_found()
  }
}

fn view_not_found() -> Element(Msg) {
  html.span([], [html.text("not found")])
}
