import gleam/uri.{type Uri}
import lustre/attribute.{type Attribute}
import modem

pub type Route {
  Index
  SignIn
  SignUp
  Guest
  Admin
  AdminLive
  AdminQuestionsList
  AdminQuestionsCreate
  AdminQuestionsView(id: String)
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
    ["admin"] -> Admin
    ["admin", "live"] -> AdminLive
    ["admin", "questions"] -> AdminQuestionsList
    ["admin", "questions", "create"] -> AdminQuestionsCreate
    ["admin", "questions", id] -> AdminQuestionsView(id)
    _ -> NotFound(uri:)
  }
}

pub fn to_path(route: Route) -> String {
  case route {
    Index -> "/"
    SignIn -> "/sign-in"
    SignUp -> "/sign-up"
    Guest -> "/guest"
    Admin -> "/admin"
    AdminLive -> "/admin/live"
    AdminQuestionsList -> "/admin/questions"
    AdminQuestionsCreate -> "/admin/questions/create"
    AdminQuestionsView(id) -> "/admin/questions/" <> id
    NotFound(_) -> "/not-found"
  }
}

pub fn href(route: Route) -> Attribute(msg) {
  route
  |> to_path
  |> attribute.href
}
