import gleam/dynamic/decode
import gleam/http/response
import gleam/json
import gleam/list
import gleam/string
import gleam/string_tree
import pog
import wisp
import youid/uuid

pub fn uuid_decoder() {
  use bit_array <- decode.then(decode.bit_array)
  case uuid.from_bit_array(bit_array) {
    Ok(uuid) -> decode.success(uuid)
    Error(_) -> decode.failure(uuid.v7(), "Uuid")
  }
}

pub type ApiError {
  CustomError(reason: String)
  DatabaseError(error: pog.QueryError)
  UnknownError
  WrongFormat(errors: List(decode.DecodeError))
}

pub fn to_wisp_response(error: ApiError) {
  case error {
    CustomError(reason) -> {
      string_tree.from_string(reason)
      |> wisp.json_response(404)
    }
    DatabaseError(error) -> {
      pog_error_to_json(error)
      |> wisp.json_response(500)
    }
    UnknownError -> {
      string_tree.from_string("Unknown error")
      |> wisp.json_response(500)
    }
    WrongFormat(errors) -> {
      decode_errors_to_json(errors)
      |> wisp.json_response(404)
    }
  }
}

pub fn decode_errors_to_json(errors: List(decode.DecodeError)) {
  let errors =
    list.map(errors, fn(error) {
      case error {
        decode.DecodeError(expected, found, path) -> #(
          string.join(path, "."),
          json.object([
            #("expected", json.string(expected)),
            #("found", json.string(found)),
          ]),
        )
      }
    })

  json.object([
    #("error", json.string("wrong_format")),
    #("details", json.object(errors)),
  ])
  |> json.to_string_tree()
}

pub fn pog_error_to_json(error: pog.QueryError) {
  case error {
    pog.ConstraintViolated(message, constraint, detail) ->
      json.object([
        #("error", json.string("constraint_violated")),
        #(
          "detail",
          json.object([
            #("message", json.string(message)),
            #("constraint", json.string(constraint)),
            #("detail", json.string(detail)),
          ]),
        ),
      ])
    _ -> json.string("Undocumented error")
    // pog.ConnectionUnavailable -> todo
    // pog.PostgresqlError(_, _, _) -> todo
    // pog.QueryTimeout -> todo
    // pog.UnexpectedArgumentCount(_, _) -> todo
    // pog.UnexpectedArgumentType(_, _) -> todo
    // pog.UnexpectedResultType(_) -> todo
  }
  |> json.to_string_tree()
}

pub fn unauthorised() -> wisp.Response {
  response.Response(401, [], wisp.Empty)
}
