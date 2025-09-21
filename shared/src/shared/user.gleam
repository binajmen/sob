import gleam/dynamic/decode
import gleam/option.{type Option}

pub type User {
  User(
    id: String,
    email: Option(String),
    first_name: Option(String),
    last_name: Option(String),
    is_admin: Bool,
  )
}

pub fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.string)
  use email <- decode.field("email", decode.optional(decode.string))
  use first_name <- decode.field("first_name", decode.optional(decode.string))
  use last_name <- decode.field("last_name", decode.optional(decode.string))
  use is_admin <- decode.field("is_admin", decode.bool)
  decode.success(User(
    id:,
    email:,
    first_name:,
    last_name:,
    is_admin:,
  ))
}
