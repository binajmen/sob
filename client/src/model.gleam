import formal/form.{type Form}
import gleam/option.{type Option}
import router.{type Route}
import rsvp

pub type Model {
  Model(
    route: Route,
    token: Option(String),
    sign_in_form: Form,
    sign_up_form: Form,
  )
}

pub type Msg {
  UserNavigatedTo(route: Route)
  UserSubmittedSignInForm(data: List(#(String, String)))
  UserSubmittedSignUpForm(data: List(#(String, String)))
  ApiAuthenticatedUser(Result(String, rsvp.Error))
}
