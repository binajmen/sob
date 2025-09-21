//// This module contains the code to run the sql queries defined in
//// `./src/vote/sql`.
//// > 🐿️ This module was generated automatically using v4.4.1 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/time/timestamp.{type Timestamp}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `create_vote` query
/// defined in `./src/vote/sql/create_vote.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateVoteRow {
  CreateVoteRow(
    id: Uuid,
    question_id: Uuid,
    user_id: Uuid,
    vote: String,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `create_vote` query
/// defined in `./src/vote/sql/create_vote.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_vote(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: Uuid,
  arg_3: String,
) -> Result(pog.Returned(CreateVoteRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use question_id <- decode.field(1, uuid_decoder())
    use user_id <- decode.field(2, uuid_decoder())
    use vote <- decode.field(3, decode.string)
    use created_at <- decode.field(4, pog.timestamp_decoder())
    use updated_at <- decode.field(5, pog.timestamp_decoder())
    decode.success(CreateVoteRow(
      id:,
      question_id:,
      user_id:,
      vote:,
      created_at:,
      updated_at:,
    ))
  }

  "insert into
  votes (question_id, user_id, vote)
values
  ($1, $2, $3)
on conflict (question_id, user_id) do update
set
  vote = excluded.vote,
  updated_at = now()
returning
  *;

"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(uuid.to_string(arg_2)))
  |> pog.parameter(pog.text(arg_3))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `delete_all_votes` query
/// defined in `./src/vote/sql/delete_all_votes.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_all_votes(
  db: pog.Connection,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "delete from votes;

"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `find_vote` query
/// defined in `./src/vote/sql/find_vote.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type FindVoteRow {
  FindVoteRow(
    id: Uuid,
    question_id: Uuid,
    user_id: Uuid,
    vote: String,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `find_vote` query
/// defined in `./src/vote/sql/find_vote.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn find_vote(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: Uuid,
) -> Result(pog.Returned(FindVoteRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use question_id <- decode.field(1, uuid_decoder())
    use user_id <- decode.field(2, uuid_decoder())
    use vote <- decode.field(3, decode.string)
    use created_at <- decode.field(4, pog.timestamp_decoder())
    use updated_at <- decode.field(5, pog.timestamp_decoder())
    decode.success(FindVoteRow(
      id:,
      question_id:,
      user_id:,
      vote:,
      created_at:,
      updated_at:,
    ))
  }

  "select
  *
from
  votes
where
  question_id = $1
  and user_id = $2;

"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(uuid.to_string(arg_2)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

// --- Encoding/decoding utils -------------------------------------------------

/// A decoder to decode `Uuid`s coming from a Postgres query.
///
fn uuid_decoder() {
  use bit_array <- decode.then(decode.bit_array)
  case uuid.from_bit_array(bit_array) {
    Ok(uuid) -> decode.success(uuid)
    Error(_) -> decode.failure(uuid.v7(), "Uuid")
  }
}
