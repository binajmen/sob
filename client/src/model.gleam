import formal/form.{type Form}
import forms.{type SignInFormData, type SignUpFormData}
import gleam/http/response.{type Response}
import router.{type Route}
import rsvp
import shared/poll.{type Poll}

pub type App {
  App(route: Route, lang: String)
}

pub type Model {
  Base(app: App)
  SignIn(app: App, form: Form(SignInFormData))
  SignUp(app: App, form: Form(SignUpFormData))
  AdminPolls(app: App, polls: List(Poll))
}

pub type Msg {
  ApiAuthenticatedUser(Result(Response(String), rsvp.Error))
  ApiReturnedPolls(Result(List(Poll), rsvp.Error))
  UserNavigatedTo(route: Route)
  UserSubmittedSignInForm(result: Result(SignInFormData, Form(SignInFormData)))
  UserSubmittedSignUpForm(result: Result(SignUpFormData, Form(SignUpFormData)))
}
