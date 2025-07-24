import formal/form.{type Form}
import forms.{type SignInFormData, type SignUpFormData}
import gleam/http/response
import router.{type Route}
import rsvp

pub type App {
  App(route: Route, lang: String)
}

pub type Model {
  Base(app: App)
  SignIn(app: App, form: Form(SignInFormData))
  SignUp(app: App, form: Form(SignUpFormData))
}

pub type Msg {
  ApiAuthenticatedUser(Result(response.Response(String), rsvp.Error))
  UserNavigatedTo(route: Route)
  UserSubmittedSignInForm(result: Result(SignInFormData, Form(SignInFormData)))
  UserSubmittedSignUpForm(result: Result(SignUpFormData, Form(SignUpFormData)))
}
