import gleam/http/response.{type Response}
import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/uri.{type Uri}
import lustre
import lustre/attribute.{type Attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import modem
import rsvp
import shared/counter.{type Counter, Counter}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", [])

  Nil
}

type Model {
  Model(route: Route, counter: Counter, error: Option(String))
}

type Route {
  Index
  About
  Session(id: String)
  NotFound(uri: Uri)
}

fn parse_route(uri: Uri) -> Route {
  case uri.path_segments(uri.path) {
    [] -> Index
    ["about"] -> About
    ["session", id] -> Session(id)
    _ -> NotFound(uri:)
  }
}

fn href(route: Route) -> Attribute(msg) {
  let url = case route {
    Index -> "/"
    About -> "/about"
    Session(id) -> "/session/" <> id
    NotFound(_) -> "/not-found"
  }

  attribute.href(url)
}

fn init(_options) -> #(Model, Effect(Msg)) {
  let route = case modem.initial_uri() {
    Ok(uri) -> parse_route(uri)
    Error(_) -> Index
  }

  let model = Model(route:, counter: Counter(0), error: option.None)
  let effect = modem.init(fn(uri) { uri |> parse_route |> UserNavigatedTo })

  #(model, effect)
}

type Msg {
  UserNavigatedTo(route: Route)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserNavigatedTo(route:) -> #(Model(..model, route:), effect.none())
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("mx-auto max-w-2xl px-32")], [
    html.nav([attribute.class("flex justify-between items-center my-16")], [
      html.h1([attribute.class("text-purple-600 font-medium text-xl")], [
        html.a([href(Index)], [html.text("My little Blog")]),
      ]),
      html.ul([attribute.class("flex space-x-8")], [
        view_header_link(current: model.route, to: Index, label: "Index"),
        view_header_link(current: model.route, to: About, label: "About"),
      ]),
    ]),
    html.main([attribute.class("my-16")], {
      case model.route {
        Index -> view_index()
        About -> view_about()
        Session(id) -> view_session(id)
        NotFound(_) -> view_not_found()
      }
    }),
  ])
}

fn view_header_link(
  to target: Route,
  current current: Route,
  label text: String,
) -> Element(msg) {
  let is_active = current == target

  html.li(
    [
      attribute.classes([
        #("border-transparent border-b-2 hover:border-purple-600", True),
        #("text-purple-600", is_active),
      ]),
    ],
    [html.a([href(target)], [html.text(text)])],
  )
}

fn view_not_found() -> List(Element(Msg)) {
  [html.span([], [html.text("not found")])]
}

fn view_session(id: String) -> List(Element(Msg)) {
  [html.span([], [html.text("session" <> id)])]
}

fn view_about() -> List(Element(Msg)) {
  [html.span([], [html.text("about")])]
}

fn view_index() -> List(Element(Msg)) {
  [html.span([], [html.text("index")])]
}
