import formal/form.{type Form}
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import model.{type Msg}

pub fn view(
  form: Form(a),
  is type_: String,
  name name: String,
  label label: String,
) -> Element(Msg) {
  let errors = form.field_error_messages(form, name) |> echo

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
