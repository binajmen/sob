import formal/form.{type Form}
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(
  form: Form(a),
  name name: String,
  label label: String,
  checked checked: Bool,
  on_change on_change: fn(Bool) -> msg,
) -> Element(msg) {
  let errors = form.field_error_messages(form, name)

  html.fieldset([attribute.class("fieldset")], [
    html.legend([attribute.class("fieldset-legend")], [html.text(label)]),
    html.label([attribute.class("cursor-pointer flex items-center gap-2")], [
      html.input([
        attribute.type_("checkbox"),
        attribute.name(name),
        attribute.class("checkbox"),
        case checked {
          True -> attribute.checked(True)
          False -> attribute.none()
        },
        event.on_check(on_change),
        case errors {
          [] -> attribute.none()
          _ -> attribute.class("checkbox-error")
        },
      ]),
      html.span([], [html.text(label)]),
    ]),
    ..list.map(errors, fn(error) {
      html.div([attribute.class("label")], [html.text(error)])
    })
  ])
}