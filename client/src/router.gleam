import gleam/uri.{type Uri}
import lustre/attribute.{type Attribute}
import modem

pub type Route {
  Index
  SignIn
  SignUp
  About
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
    ["signin"] -> SignIn
    ["signup"] -> SignUp
    ["about"] -> About
    ["session", id] -> Session(id)
    _ -> NotFound(uri:)
  }
}

pub fn href(route: Route) -> Attribute(msg) {
  let url = case route {
    Index -> "/"
    SignIn -> "/signin"
    SignUp -> "/signup"
    About -> "/about"
    Session(id) -> "/session/" <> id
    NotFound(_) -> "/not-found"
  }

  attribute.href(url)
}
