import pog

pub type Context {
  Context(db: pog.Connection, static_directory: String)
}
