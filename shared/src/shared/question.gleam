import gleam/dynamic/decode

pub type Question {
  Question(id: String, poll_id: String, prompt: String)
}

pub fn question_decoder() -> decode.Decoder(Question) {
  use id <- decode.field("id", decode.string)
  use poll_id <- decode.field("poll_id", decode.string)
  use prompt <- decode.field("prompt", decode.string)
  decode.success(Question(id:, poll_id:, prompt:))
}
