import gleam/dynamic/decode

pub type VoteType {
  Yes
  No
  Blank
}

pub type Vote {
  Vote(id: String, question_id: String, user_id: String, vote: VoteType)
}

pub fn vote_decoder() -> decode.Decoder(Vote) {
  use id <- decode.field("id", decode.string)
  use question_id <- decode.field("question_id", decode.string)
  use user_id <- decode.field("user_id", decode.string)
  use vote <- decode.field("vote", vote_type_decoder())
  decode.success(Vote(id:, question_id:, user_id:, vote:))
}

pub fn vote_type_decoder() -> decode.Decoder(VoteType) {
  use vote_str <- decode.then(decode.string)
  case vote_str {
    "yes" -> decode.success(Yes)
    "no" -> decode.success(No)
    "blank" -> decode.success(Blank)
    _ -> decode.failure(Yes, "VoteType")
  }
}

pub fn vote_type_to_string(vote: VoteType) -> String {
  case vote {
    Yes -> "yes"
    No -> "no"
    Blank -> "blank"
  }
}

pub fn vote_type_from_string(vote_str: String) -> Result(VoteType, Nil) {
  case vote_str {
    "yes" -> Ok(Yes)
    "no" -> Ok(No)
    "blank" -> Ok(Blank)
    _ -> Error(Nil)
  }
}
