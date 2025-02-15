import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html.{div, li, ol, span, text}
import lustre/event
import lustre/ui

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model {
  Model(input: String, notes: Dict(String, Bool))
}

fn init(_) -> #(Model, Effect(Msg)) {
  let model = Model(input: "", notes: dict.new())

  #(
    model,
    effect.batch([read_localstorage("input"), read_localstorage("notes")]),
  )
}

pub opaque type Msg {
  AddNote
  ToggleStatus(String)
  UserInput(String)
  CacheInput(Result(String, Nil))
  CacheNotes(Result(String, Nil))
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    AddNote -> {
      #(
        Model(input: "", notes: dict.insert(model.notes, model.input, False)),
        write_localstorage("notes", model.notes),
        // effect.none(),
      )
    }
    ToggleStatus(note) -> {
      case dict.get(model.notes, note) {
        Ok(status) -> #(
          Model(..model, notes: dict.insert(model.notes, note, !status)),
          effect.none(),
        )
        Error(_) -> panic as "Note not found"
      }
    }
    UserInput(input) -> {
      #(Model(..model, input:), write_localstorage("input", input))
    }
    CacheInput(Ok(input)) -> #(Model(..model, input:), effect.none())
    CacheInput(Error(_)) -> #(model, effect.none())
    CacheNotes(Ok(notes)) -> {
      io.debug(notes)
      // #(Model(..model, notes:), effect.none())
      #(model, effect.none())
    }
    CacheNotes(Error(_)) -> #(model, effect.none())
  }
}

fn read_localstorage(key: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    case key {
      "input" ->
        do_read_localstorage(key)
        |> CacheInput
        |> dispatch
      "notes" ->
        do_read_localstorage(key)
        |> CacheNotes
        |> dispatch
      _ -> Nil
    }
  })
}

@external(javascript, "./app.ffi.mjs", "read_localstorage")
fn do_read_localstorage(_key: String) -> Result(a, Nil) {
  Error(Nil)
}

fn write_localstorage(key: String, value: a) -> Effect(Msg) {
  effect.from(fn(_) { do_write_localstorage(key, value) })
}

@external(javascript, "./app.ffi.mjs", "write_localstorage")
fn do_write_localstorage(_key: String, _value: a) -> Nil {
  Nil
}

fn view(model: Model) -> Element(Msg) {
  div([], [view_notes(model), view_new_note(model)])
}

fn view_notes(model: Model) -> Element(Msg) {
  element.keyed(ol([], _), {
    use #(note, status) <- list.map(dict.to_list(model.notes))
    let item = view_note(note, status)
    #(note, item)
  })
}

fn view_note(note: String, status: Bool) -> Element(Msg) {
  li([], [
    span([], [text(note)]),
    ui.input([
      attribute.type_("checkbox"),
      attribute.checked(status),
      event.on_click(ToggleStatus(note)),
    ]),
  ])
}

fn view_new_note(model: Model) -> Element(Msg) {
  div([], [
    ui.input([attribute.value(model.input), event.on_input(UserInput)]),
    ui.button([event.on_click(AddNote)], [html.text("Add")]),
  ])
}
