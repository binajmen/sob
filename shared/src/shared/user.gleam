import gleam/dynamic/decode

pub type User {
  User(id: String, is_admin: Bool)
}

pub fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.string)
  use is_admin <- decode.field("is_admin", decode.bool)
  decode.success(User(id:, is_admin:))
}
