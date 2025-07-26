import gleam/uri.{type Uri}
import lustre/attribute.{type Attribute}
import modem

pub type Route {
  Index
  SignIn
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
    _ -> NotFound(uri:)
  }
}

pub fn to_path(route: Route) -> String {
  case route {
    Index -> "/"
    SignIn -> "/sign-in"
    NotFound(_) -> "/not-found"
  }
}

pub fn href(route: Route) -> Attribute(msg) {
  route
  |> to_path
  |> attribute.href
}
