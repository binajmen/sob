import gleam/uri.{type Uri}
import lustre/attribute.{type Attribute}
import modem

pub type Route {
  Index
  About
  SignIn
  SignUp
  AdminPolls
  Session(id: String)
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
    ["about"] -> About
    ["sign-in"] -> SignIn
    ["sign-up"] -> SignUp
    ["admin", "polls"] -> AdminPolls
    ["session", id] -> Session(id)
    _ -> NotFound(uri:)
  }
}

pub fn href(route: Route) -> Attribute(msg) {
  let url = case route {
    Index -> "/"
    About -> "/about"
    SignIn -> "/sign-in"
    SignUp -> "/sign-up"
    AdminPolls -> "/admin/polls"
    Session(id) -> "/session/" <> id
    NotFound(_) -> "/not-found"
  }

  attribute.href(url)
}
