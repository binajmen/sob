import gleam/dynamic/decode
import gleam/time/timestamp.{type Timestamp}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `list_polls` query
/// defined in `./src/poll/sql/list_polls.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.0.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListPollsRow {
  ListPollsRow(
    id: Uuid,
    name: String,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `list_polls` query
/// defined in `./src/poll/sql/list_polls.sql`.
///
/// > 🐿️ This function was generated automatically using v4.0.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_polls(db) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use name <- decode.field(1, decode.string)
    use created_at <- decode.field(2, pog.timestamp_decoder())
    use updated_at <- decode.field(3, pog.timestamp_decoder())
    decode.success(ListPollsRow(id:, name:, created_at:, updated_at:))
  }

  "select
  *
from
  polls;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_poll` query
/// defined in `./src/poll/sql/create_poll.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.0.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreatePollRow {
  CreatePollRow(id: Uuid)
}

/// Runs the `create_poll` query
/// defined in `./src/poll/sql/create_poll.sql`.
///
/// > 🐿️ This function was generated automatically using v4.0.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_poll(db, arg_1) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(CreatePollRow(id:))
  }

  "insert into
  polls (name)
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
