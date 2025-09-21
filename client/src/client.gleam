import gleam/option.{type Option, None, Some}
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import modem
import router.{type Route}
import routes/admin
import routes/admin/live
import routes/admin/questions/create as admin_questions_create
import routes/admin/questions/list as admin_questions_list
import routes/admin/questions/view as admin_questions_view
import routes/admin/users/list as admin_users_list
import routes/guest
import routes/poll
import routes/sign_in
import routes/sign_up
import rsvp
import shared/user.{type User}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", [])

  Nil
}

pub type Model {
  Model(route: Route, lang: String, user: Option(User), page: Page)
}

pub type Page {
  Poll(poll.Model)
  SignIn(sign_in.Model)
  SignUp(sign_up.Model)
  Guest(guest.Model)
  Admin
  AdminLive(live.Model)
  AdminQuestionsList(admin_questions_list.Model)
  AdminQuestionsCreate(admin_questions_create.Model)
  AdminQuestionsView(admin_questions_view.Model)
  AdminUsersList(admin_users_list.Model)
}

pub type Msg {
  UserNavigatedTo(route: Route)
  ApiReturnedUser(Result(User, rsvp.Error))
  PollMsg(poll.Msg)
  SignInMsg(sign_in.Msg)
  SignUpMsg(sign_up.Msg)
  GuestMsg(guest.Msg)
  AdminLiveMsg(live.Msg)
  AdminQuestionsListMsg(admin_questions_list.Msg)
  AdminQuestionsCreateMsg(admin_questions_create.Msg)
  AdminQuestionsViewMsg(admin_questions_view.Msg)
  AdminUsersListMsg(admin_users_list.Msg)
}

fn init(_options) -> #(Model, Effect(Msg)) {
  let route = router.initial_route()
  let model = Model(route: route, lang: "en", user: None, page: Admin)
  let #(model, page_effect) = init_route(route, model)
  let effect =
    effect.batch([
      modem.init(fn(uri) { uri |> router.parse_route |> UserNavigatedTo }),
      page_effect,
      retrieve_user(ApiReturnedUser),
    ])

  #(model, effect)
}

fn retrieve_user(
  on_response handle_response: fn(Result(User, rsvp.Error)) -> msg,
) -> Effect(msg) {
  let url = "/api/auth/me"
  let decoder = user.user_decoder()
  let handler = rsvp.expect_json(decoder, handle_response)
  rsvp.get(url, handler)
}

fn init_route(route: Route, model: Model) -> #(Model, Effect(Msg)) {
  case route {
    router.Poll -> {
      let #(page_model, effect) = poll.init()
      #(
        Model(..model, route:, page: Poll(page_model)),
        effect.map(effect, PollMsg),
      )
    }

    router.SignIn -> {
      let #(page_model, effect) = sign_in.init()
      #(
        Model(..model, route:, page: SignIn(page_model)),
        effect.map(effect, SignInMsg),
      )
    }
    router.SignUp -> {
      let #(page_model, effect) = sign_up.init()
      #(
        Model(..model, route:, page: SignUp(page_model)),
        effect.map(effect, SignUpMsg),
      )
    }
    router.Guest -> {
      let #(page_model, effect) = guest.init()
      #(
        Model(..model, route:, page: Guest(page_model)),
        effect.map(effect, GuestMsg),
      )
    }
    router.Admin -> #(Model(..model, route:, page: Admin), effect.none())
    router.AdminLive -> {
      let #(page_model, effect) = live.init()
      #(
        Model(..model, route:, page: AdminLive(page_model)),
        effect.map(effect, AdminLiveMsg),
      )
    }
    router.AdminQuestionsList -> {
      let #(page_model, effect) = admin_questions_list.init()
      #(
        Model(..model, route:, page: AdminQuestionsList(page_model)),
        effect.map(effect, AdminQuestionsListMsg),
      )
    }
    router.AdminQuestionsCreate -> {
      let #(page_model, effect) = admin_questions_create.init()
      #(
        Model(..model, route:, page: AdminQuestionsCreate(page_model)),
        effect.map(effect, AdminQuestionsCreateMsg),
      )
    }
    router.AdminQuestionsView(id) -> {
      let #(page_model, effect) = admin_questions_view.init(id)
      #(
        Model(..model, route:, page: AdminQuestionsView(page_model)),
        effect.map(effect, AdminQuestionsViewMsg),
      )
    }
    router.AdminUsersList -> {
      let #(page_model, effect) = admin_users_list.init()
      #(
        Model(..model, route:, page: AdminUsersList(page_model)),
        effect.map(effect, AdminUsersListMsg),
      )
    }
    _ -> #(model, effect.none())
  }
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserNavigatedTo(route) -> init_route(route, model)

    ApiReturnedUser(Ok(user)) -> #(
      Model(..model, user: Some(user)),
      effect.none(),
    )
    ApiReturnedUser(Error(_)) -> #(
      Model(..model, user: None),
      case model.route {
        router.SignIn | router.SignUp | router.Guest -> effect.none()
        _ -> modem.push(router.to_path(router.SignIn), None, None)
      },
    )

    PollMsg(msg) -> {
      let assert Poll(page_model) = model.page
      let #(page_model, effect) = poll.update(page_model, msg)
      #(Model(..model, page: Poll(page_model)), effect.map(effect, PollMsg))
    }

    SignInMsg(msg) -> {
      let assert SignIn(page_model) = model.page
      let #(page_model, effect) = sign_in.update(page_model, msg)
      #(Model(..model, page: SignIn(page_model)), effect.map(effect, SignInMsg))
    }

    SignUpMsg(msg) -> {
      let assert SignUp(page_model) = model.page
      let #(page_model, effect) = sign_up.update(page_model, msg)
      #(Model(..model, page: SignUp(page_model)), effect.map(effect, SignUpMsg))
    }

    GuestMsg(msg) -> {
      let assert Guest(page_model) = model.page
      let #(page_model, effect) = guest.update(page_model, msg)
      #(Model(..model, page: Guest(page_model)), effect.map(effect, GuestMsg))
    }

    AdminLiveMsg(msg) -> {
      let assert AdminLive(page_model) = model.page
      let #(page_model, effect) = live.update(page_model, msg)
      #(
        Model(..model, page: AdminLive(page_model)),
        effect.map(effect, AdminLiveMsg),
      )
    }

    AdminQuestionsListMsg(msg) -> {
      let assert AdminQuestionsList(page_model) = model.page
      let #(page_model, effect) = admin_questions_list.update(page_model, msg)
      #(
        Model(..model, page: AdminQuestionsList(page_model)),
        effect.map(effect, AdminQuestionsListMsg),
      )
    }

    AdminQuestionsCreateMsg(msg) -> {
      let assert AdminQuestionsCreate(page_model) = model.page
      let #(page_model, effect) = admin_questions_create.update(page_model, msg)
      #(
        Model(..model, page: AdminQuestionsCreate(page_model)),
        effect.map(effect, AdminQuestionsCreateMsg),
      )
    }

    AdminQuestionsViewMsg(msg) -> {
      let assert AdminQuestionsView(page_model) = model.page
      let #(page_model, effect) = admin_questions_view.update(page_model, msg)
      #(
        Model(..model, page: AdminQuestionsView(page_model)),
        effect.map(effect, AdminQuestionsViewMsg),
      )
    }

    AdminUsersListMsg(msg) -> {
      let assert AdminUsersList(page_model) = model.page
      let #(page_model, effect) = admin_users_list.update(page_model, msg)
      #(
        Model(..model, page: AdminUsersList(page_model)),
        effect.map(effect, AdminUsersListMsg),
      )
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  case model.route, model.page {
    router.Poll, Poll(model) ->
      poll.view(model)
      |> element.map(PollMsg)

    router.SignIn, SignIn(model) ->
      sign_in.view(model)
      |> element.map(SignInMsg)

    router.SignUp, SignUp(model) ->
      sign_up.view(model.form)
      |> element.map(SignUpMsg)

    router.Guest, Guest(model) ->
      guest.view(model.form)
      |> element.map(GuestMsg)

    router.Admin, Admin -> admin.view()

    router.AdminLive, AdminLive(model) ->
      live.view(model)
      |> element.map(AdminLiveMsg)

    router.AdminQuestionsList, AdminQuestionsList(model) ->
      admin_questions_list.view(model.questions)
      |> element.map(AdminQuestionsListMsg)

    router.AdminQuestionsCreate, AdminQuestionsCreate(model) ->
      admin_questions_create.view(model.form)
      |> element.map(AdminQuestionsCreateMsg)

    router.AdminQuestionsView(_id), AdminQuestionsView(model) ->
      admin_questions_view.view(model.question, model.form)
      |> element.map(AdminQuestionsViewMsg)

    router.AdminUsersList, AdminUsersList(model) ->
      admin_users_list.view(model.users)
      |> element.map(AdminUsersListMsg)

    _, _ -> view_not_found()
  }
}

fn view_not_found() -> Element(Msg) {
  html.span([], [html.text("not found")])
}
