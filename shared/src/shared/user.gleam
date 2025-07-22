import gleam/time/timestamp.{type Timestamp}

pub type User {
  User(
    id: String,
    email: String,
    is_admin: Bool,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}
