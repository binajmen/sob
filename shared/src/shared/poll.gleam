import gleam/dynamic/decode

pub type Poll {
  Poll(id: String, name: String)
}

pub fn poll_decoder() -> decode.Decoder(Poll) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  decode.success(Poll(id:, name:))
}
