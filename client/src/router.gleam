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
  AdminPolls
  AdminPollsCreate
  AdminPollsView(id: String)
  AdminPollsQuestions(id: String)
  AdminPollsQuestionsCreate(id: String)
  NotFound(uri: Uri)
}

pub fn initial_route() -> Route {
  case modem.initial_uri() {
    Ok(uri) -> parse_route(uri)
    Error(_) -> Index
  }
}

pub fn parse_route(uri: Uri) -> Route {
  case uri.path_segments(uri.path) {
    [] -> Index
    ["sign-in"] -> SignIn
    ["sign-up"] -> SignUp
    ["guest"] -> Guest
    ["polls"] -> Polls
    ["polls", id] -> PollsView(id)
    ["admin", "polls"] -> AdminPolls
    ["admin", "polls", "create"] -> AdminPollsCreate
    ["admin", "polls", id] -> AdminPollsView(id)
    ["admin", "polls", id, "questions"] -> AdminPollsQuestions(id)
    ["admin", "polls", id, "questions", "create"] ->
      AdminPollsQuestionsCreate(id)
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
    AdminPolls -> "/admin/polls"
    AdminPollsCreate -> "/admin/polls/create"
    AdminPollsView(id) -> "/admin/polls/" <> id
    AdminPollsQuestions(id) -> "/admin/polls/" <> id <> "/questions"
    AdminPollsQuestionsCreate(id) ->
      "/admin/polls/" <> id <> "/questions/create"
    NotFound(_) -> "/not-found"
  }
}

pub fn href(route: Route) -> Attribute(msg) {
  route
  |> to_path
  |> attribute.href
}
