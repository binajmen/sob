import gleam/dynamic/decode
import gleam/time/timestamp.{type Timestamp}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `create_session` query
/// defined in `./src/auth/sql/create_session.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.0.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateSessionRow {
  CreateSessionRow(id: Uuid)
}

/// Runs the `create_session` query
/// defined in `./src/auth/sql/create_session.sql`.
///
/// > 🐿️ This function was generated automatically using v4.0.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_session(db, arg_1) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(CreateSessionRow(id:))
  }

  "insert into sessions (user_id) values ($1) returning id;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `find_user_by_session` query
/// defined in `./src/auth/sql/find_user_by_session.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.0.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type FindUserBySessionRow {
  FindUserBySessionRow(
    id: Uuid,
    email: String,
    password_hash: String,
    is_admin: Bool,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `find_user_by_session` query
/// defined in `./src/auth/sql/find_user_by_session.sql`.
///
/// > 🐿️ This function was generated automatically using v4.0.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn find_user_by_session(db, arg_1) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use email <- decode.field(1, decode.string)
    use password_hash <- decode.field(2, decode.string)
    use is_admin <- decode.field(3, decode.bool)
    use created_at <- decode.field(4, pog.timestamp_decoder())
    use updated_at <- decode.field(5, pog.timestamp_decoder())
    decode.success(FindUserBySessionRow(
      id:,
      email:,
      password_hash:,
      is_admin:,
      created_at:,
      updated_at:,
    ))
  }

  "select u.*
from users u
inner join sessions s on u.id = s.user_id
where s.id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_user` query
/// defined in `./src/auth/sql/create_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.0.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateUserRow {
  CreateUserRow(id: Uuid)
}

/// Runs the `create_user` query
/// defined in `./src/auth/sql/create_user.sql`.
///
/// > 🐿️ This function was generated automatically using v4.0.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_user(db, arg_1, arg_2) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(CreateUserRow(id:))
  }

  "insert into users (email, password_hash) values ($1, $2) returning id;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `find_user_by_email` query
/// defined in `./src/auth/sql/find_user_by_email.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.0.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type FindUserByEmailRow {
  FindUserByEmailRow(
    id: Uuid,
    email: String,
    password_hash: String,
    is_admin: Bool,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `find_user_by_email` query
/// defined in `./src/auth/sql/find_user_by_email.sql`.
///
/// > 🐿️ This function was generated automatically using v4.0.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn find_user_by_email(db, arg_1) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use email <- decode.field(1, decode.string)
    use password_hash <- decode.field(2, decode.string)
    use is_admin <- decode.field(3, decode.bool)
    use created_at <- decode.field(4, pog.timestamp_decoder())
    use updated_at <- decode.field(5, pog.timestamp_decoder())
    decode.success(FindUserByEmailRow(
      id:,
      email:,
      password_hash:,
      is_admin:,
      created_at:,
      updated_at:,
    ))
  }

  "select * from users where email = $1;
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
