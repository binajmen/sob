import gleam/dynamic/decode

pub type Question {
  Question(id: String, prompt: String)
}

pub fn question_decoder() -> decode.Decoder(Question) {
  use id <- decode.field("id", decode.string)
  use prompt <- decode.field("prompt", decode.string)
  decode.success(Question(id:, prompt:))
}

pub type Result {
  Result(yes: Int, no: Int, blank: Int)
}

pub fn result_decoder() -> decode.Decoder(Result) {
  use yes <- decode.field("yes", decode.int)
  use no <- decode.field("no", decode.int)
  use blank <- decode.field("blank", decode.int)
  decode.success(Result(yes:, no:, blank:))
}
