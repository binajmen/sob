import formal/form.{type Form}
import forms.{type SignInFormData, type SignUpFormData}
import gleam/http/response
import gleam/option
import router.{type Route}
import rsvp

pub type Base {
  Base(route: Route, session_id: option.Option(String))
}

pub type Model {
  Model(base: Base)
  SignIn(base: Base, form: Form(SignInFormData))
  SignUp(base: Base, form: Form(SignUpFormData))
}

pub type Msg {
  ApiAuthenticatedUser(Result(response.Response(String), rsvp.Error))
  UserNavigatedTo(route: Route)
  UserSubmittedSignInForm(result: Result(SignInFormData, Form(SignInFormData)))
  UserSubmittedSignUpForm(result: Result(SignUpFormData, Form(SignUpFormData)))
}
