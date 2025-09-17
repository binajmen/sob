//// This module contains the code to run the sql queries defined in
//// `./src/question/sql`.
//// > 🐿️ This module was generated automatically using v4.4.1 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/time/timestamp.{type Timestamp}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `create_question` query
/// defined in `./src/question/sql/create_question.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateQuestionRow {
  CreateQuestionRow(id: Uuid)
}

/// Runs the `create_question` query
/// defined in `./src/question/sql/create_question.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_question(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(CreateQuestionRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(CreateQuestionRow(id:))
  }

  "insert into
  questions (prompt)
values
  ($1)
returning
  id;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `delete_question` query
/// defined in `./src/question/sql/delete_question.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type DeleteQuestionRow {
  DeleteQuestionRow(
    id: Uuid,
    prompt: String,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `delete_question` query
/// defined in `./src/question/sql/delete_question.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_question(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(DeleteQuestionRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use prompt <- decode.field(1, decode.string)
    use created_at <- decode.field(2, pog.timestamp_decoder())
    use updated_at <- decode.field(3, pog.timestamp_decoder())
    decode.success(DeleteQuestionRow(id:, prompt:, created_at:, updated_at:))
  }

  "delete from questions
where
  id = $1
returning
  *;"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `find_question` query
/// defined in `./src/question/sql/find_question.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type FindQuestionRow {
  FindQuestionRow(
    id: Uuid,
    prompt: String,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `find_question` query
/// defined in `./src/question/sql/find_question.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn find_question(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(FindQuestionRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use prompt <- decode.field(1, decode.string)
    use created_at <- decode.field(2, pog.timestamp_decoder())
    use updated_at <- decode.field(3, pog.timestamp_decoder())
    decode.success(FindQuestionRow(id:, prompt:, created_at:, updated_at:))
  }

  "select
  *
from
  questions
where
  id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_questions` query
/// defined in `./src/question/sql/list_questions.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListQuestionsRow {
  ListQuestionsRow(
    id: Uuid,
    prompt: String,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `list_questions` query
/// defined in `./src/question/sql/list_questions.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_questions(
  db: pog.Connection,
) -> Result(pog.Returned(ListQuestionsRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use prompt <- decode.field(1, decode.string)
    use created_at <- decode.field(2, pog.timestamp_decoder())
    use updated_at <- decode.field(3, pog.timestamp_decoder())
    decode.success(ListQuestionsRow(id:, prompt:, created_at:, updated_at:))
  }

  "select
  *
from
  questions
order by
  created_at asc;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_question` query
/// defined in `./src/question/sql/update_question.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateQuestionRow {
  UpdateQuestionRow(
    id: Uuid,
    prompt: String,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `update_question` query
/// defined in `./src/question/sql/update_question.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_question(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: String,
) -> Result(pog.Returned(UpdateQuestionRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use prompt <- decode.field(1, decode.string)
    use created_at <- decode.field(2, pog.timestamp_decoder())
    use updated_at <- decode.field(3, pog.timestamp_decoder())
    decode.success(UpdateQuestionRow(id:, prompt:, created_at:, updated_at:))
  }

  "update questions
set
  prompt = $2,
  updated_at = now()
where
  id = $1
returning
  *;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
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
