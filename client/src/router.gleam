import gleam/uri.{type Uri}
import lustre/attribute.{type Attribute}
import modem

pub type Route {
  Poll
  SignIn
  SignUp
  Guest
  Admin
  AdminLive
  AdminReset
  AdminQuestionsList
  AdminQuestionsCreate
  AdminQuestionsView(id: String)
  AdminUsersList
  NotFound(uri: Uri)
}

pub fn initial_route() -> Route {
  case modem.initial_uri() {
    Ok(uri) -> parse_route(uri)
    Error(_) -> Poll
  }
}

pub fn parse_route(uri: Uri) -> Route {
  case uri.path_segments(uri.path) |> echo {
    [] -> Poll
    ["sign-in"] -> SignIn
    ["sign-up"] -> SignUp
    ["guest"] -> Guest
    ["admin"] -> Admin
    ["admin", "live"] -> AdminLive
    ["admin", "reset"] -> AdminReset
    ["admin", "questions"] -> AdminQuestionsList
    ["admin", "questions", "create"] -> AdminQuestionsCreate
    ["admin", "questions", id] -> AdminQuestionsView(id)
    ["admin", "users"] -> AdminUsersList
    _ -> NotFound(uri:)
  }
}

pub fn to_path(route: Route) -> String {
  case route {
    Poll -> "/"
    SignIn -> "/sign-in"
    SignUp -> "/sign-up"
    Guest -> "/guest"
    Admin -> "/admin"
    AdminLive -> "/admin/live"
    AdminReset -> "/admin/reset"
    AdminQuestionsList -> "/admin/questions"
    AdminQuestionsCreate -> "/admin/questions/create"
    AdminQuestionsView(id) -> "/admin/questions/" <> id
    AdminUsersList -> "/admin/users"
    NotFound(_) -> "/not-found"
  }
}

pub fn href(route: Route) -> Attribute(msg) {
  route
  |> to_path
  |> attribute.href
}
