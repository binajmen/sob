import gleam/dynamic/decode

pub type Question {
  Question(id: String, prompt: String, position: Int)
}

pub fn question_decoder() -> decode.Decoder(Question) {
  use id <- decode.field("id", decode.string)
  use prompt <- decode.field("prompt", decode.string)
  use position <- decode.field("position", decode.int)
  decode.success(Question(id:, prompt:, position:))
}

pub type Result {
  Result(
    id: String,
    prompt: String,
    yes_count: Int,
    no_count: Int,
    blank_count: Int,
  )
}

pub fn result_decoder() -> decode.Decoder(Result) {
  use id <- decode.field("id", decode.string)
  use prompt <- decode.field("prompt", decode.string)
  use yes_count <- decode.field("yes_count", decode.int)
  use no_count <- decode.field("no_count", decode.int)
  use blank_count <- decode.field("blank_count", decode.int)
  decode.success(Result(id:, prompt:, yes_count:, no_count:, blank_count:))
}
