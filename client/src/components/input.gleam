import formal/form.{type Form}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import model.{type Msg}

pub fn view(
  form: Form,
  is type_: String,
  name name: String,
  label label: String,
) -> Element(Msg) {
  let state = form.field_state(form, name)

  html.label([], [
    html.span([attribute.class("block text-sm/6 font-medium text-gray-900")], [
      html.text(label),
    ]),
    html.div([attribute.class("mt-2")], [
      html.input([
        attribute.type_(type_),
        attribute.name(name),
        attribute.placeholder(label),
        attribute.class(
          "block w-full rounded-md bg-white px-3 py-1.5 text-base ",
        ),
        attribute.class("outline-1 -outline-offset-1 "),
        attribute.class("focus:outline-2 focus:-outline-offset-2"),
        attribute.class("sm:text-sm/6"),
        case state {
          Ok(_) ->
            attribute.class(
              "text-gray-900 outline-gray-300 placeholder:text-gray-400 focus:outline-indigo-600",
            )
          Error(_) ->
            attribute.class(
              "text-red-900 outline-red-300 placeholder:text-red-300 focus:outline-red-600",
            )
        },
      ]),
      case state {
        Ok(_) -> element.none()
        Error(error_message) ->
          html.p([attribute.class("mt-2 text-sm text-red-600")], [
            html.text(error_message),
          ])
      },
    ]),
  ])
}
