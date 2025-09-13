import formal/form.{type Form}
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(
  form: Form(a),
  name name: String,
  label label: String,
  value value: Option(String),
) -> Element(msg) {
  let errors = form.field_error_messages(form, name)

  html.fieldset([attribute.class("fieldset")], [
    html.legend([attribute.class("fieldset-legend")], [html.text(label)]),
    html.textarea(
      [
        attribute.name(name),
        attribute.class("textarea textarea-bordered w-full"),
        attribute.attribute("rows", "4"),
        case errors {
          [] -> attribute.none()
          _ ->
            attribute.class("textarea textarea-bordered textarea-error w-full")
        },
      ],
      case value {
        None -> ""
        Some(value) -> value
      },
    ),
    ..list.map(errors, fn(error) {
      html.p([attribute.class("label")], [html.text(error)])
    })
  ])
}
