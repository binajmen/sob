import gleam/float
import gleam/int
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(yes: Int, no: Int, blank: Int) -> Element(msg) {
  let max = yes |> int.max(no) |> int.max(blank)

  let #(yes_size, no_size, blank_size) = case max {
    0 -> #(0.0, 0.0, 0.0)
    _ -> {
      let yes_size = int.to_float(yes) /. int.to_float(max)
      let no_size = int.to_float(no) /. int.to_float(max)
      let blank_size = int.to_float(blank) /. int.to_float(max)
      #(yes_size, no_size, blank_size)
    }
  }

  html.table(
    [
      attribute.class("charts-css bar show-labels data-spacing-2 data-outside"),
    ],
    [
      html.tbody([], [
        html.tr([], [
          html.th([attribute.scope("row")], [html.text("Yes")]),
          html.td(
            [
              attribute.styles([
                #("--size", float.to_string(yes_size)),
                #("--color", "#2052dd"),
              ]),
            ],
            [
              html.span([attribute.class("data")], [
                html.text(int.to_string(yes)),
              ]),
            ],
          ),
        ]),
        html.tr([], [
          html.th([attribute.scope("row")], [html.text("No")]),
          html.td(
            [
              attribute.styles([
                #("--size", float.to_string(no_size)),
                #("--color", "#2052dd"),
              ]),
            ],
            [
              html.span([attribute.class("data")], [
                html.text(int.to_string(no)),
              ]),
            ],
          ),
        ]),
        html.tr([], [
          html.th([attribute.scope("row")], [html.text("Abstain")]),
          html.td(
            [
              attribute.styles([
                #("--size", float.to_string(blank_size)),
                #("--color", "#2052dd"),
              ]),
            ],
            [
              html.span([attribute.class("data")], [
                html.text(int.to_string(blank)),
              ]),
            ],
          ),
        ]),
      ]),
    ],
  )
}
