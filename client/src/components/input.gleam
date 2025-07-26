import formal/form.{type Form}
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(
  form: Form(a),
  is type_: String,
  name name: String,
  label label: String,
) -> Element(msg) {
  let errors = form.field_error_messages(form, name)

  html.fieldset([attribute.class("fieldset")], [
    html.legend([attribute.class("fieldset-legend")], [html.text(label)]),
    html.input([
      attribute.type_(type_),
      attribute.name(name),
      attribute.class("input"),
      case errors {
        [] -> attribute.class("input-neutral")
        _ -> attribute.class("input-error")
      },
    ]),
    ..list.map(errors, fn(error) {
      html.p([attribute.class("label")], [html.text(error)])
    })
  ])
}
