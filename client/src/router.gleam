import gleam/uri.{type Uri}
import lustre/attribute.{type Attribute}
import modem

pub type Route {
  Index
  SignIn
  SignUp
  Guest
  Polls
  PollsView(id: String)
  Admin
  AdminPolls
  AdminPollsCreate
  AdminPollsView(id: String)
  AdminQuestions(poll_id: String)
  AdminQuestionsCreate(poll_id: String)
  AdminQuestionsView(poll_id: String, id: String)
  NotFound(uri: Uri)
}

pub fn initial_route() -> Route {
  case modem.initial_uri() {
    Ok(uri) -> parse_route(uri)
    Error(_) -> Index
  }
}

pub fn parse_route(uri: Uri) -> Route {
  case uri.path_segments(uri.path) |> echo {
    [] -> Index
    ["sign-in"] -> SignIn
    ["sign-up"] -> SignUp
    ["guest"] -> Guest
    ["polls"] -> Polls
    ["polls", id] -> PollsView(id)
    ["admin"] -> Admin
    ["admin", "polls"] -> AdminPolls
    ["admin", "polls", "create"] -> AdminPollsCreate
    ["admin", "polls", id] -> AdminPollsView(id)
    ["admin", "polls", poll_id, "questions"] -> AdminQuestions(poll_id)
    ["admin", "polls", poll_id, "questions", "create"] ->
      AdminQuestionsCreate(poll_id)
    ["admin", "polls", poll_id, "questions", id] ->
      AdminQuestionsView(poll_id, id)
    _ -> NotFound(uri:)
  }
}

pub fn to_path(route: Route) -> String {
  case route {
    Index -> "/"
    SignIn -> "/sign-in"
    SignUp -> "/sign-up"
    Guest -> "/guest"
    Polls -> "/polls"
    PollsView(id) -> "/polls/" <> id
    Admin -> "/admin"
    AdminPolls -> "/admin/polls"
    AdminPollsCreate -> "/admin/polls/create"
    AdminPollsView(id) -> "/admin/polls/" <> id
    AdminQuestions(id) -> "/admin/polls/" <> id <> "/questions"
    AdminQuestionsCreate(id) -> "/admin/polls/" <> id <> "/questions/create"
    AdminQuestionsView(poll_id, id) ->
      "/admin/polls/" <> poll_id <> "/questions/" <> id
    NotFound(_) -> "/not-found"
  }
}

pub fn href(route: Route) -> Attribute(msg) {
  route
  |> to_path
  |> attribute.href
}
