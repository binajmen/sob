//// This module contains the code to run the sql queries defined in
//// `./src/session/sql`.
//// > 🐿️ This module was generated automatically using v4.4.1 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/time/timestamp.{type Timestamp}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `find_session` query
/// defined in `./src/session/sql/find_session.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type FindSessionRow {
  FindSessionRow(
    id: Uuid,
    user_id: Uuid,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `find_session` query
/// defined in `./src/session/sql/find_session.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn find_session(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(FindSessionRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use user_id <- decode.field(1, uuid_decoder())
    use created_at <- decode.field(2, pog.timestamp_decoder())
    use updated_at <- decode.field(3, pog.timestamp_decoder())
    decode.success(FindSessionRow(id:, user_id:, created_at:, updated_at:))
  }

  "select
  *
from
  sessions
where
  id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_sessions` query
/// defined in `./src/session/sql/list_sessions.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListSessionsRow {
  ListSessionsRow(
    id: Uuid,
    user_id: Uuid,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `list_sessions` query
/// defined in `./src/session/sql/list_sessions.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_sessions(
  db: pog.Connection,
) -> Result(pog.Returned(ListSessionsRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use user_id <- decode.field(1, uuid_decoder())
    use created_at <- decode.field(2, pog.timestamp_decoder())
    use updated_at <- decode.field(3, pog.timestamp_decoder())
    decode.success(ListSessionsRow(id:, user_id:, created_at:, updated_at:))
  }

  "select
  *
from
  sessions;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `update_session` query
/// defined in `./src/session/sql/update_session.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_session(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: Uuid,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "update
  sessions
set
  user_id = $2
where
  id = $1
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
