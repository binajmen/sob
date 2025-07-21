import formal/form.{type Form}
import gleam/option.{type Option}
import router.{type Route}

pub type Model {
  Model(route: Route, user_id: Option(String), login_form: Form)
}

pub type Msg {
  UserNavigatedTo(route: Route)
  UserSubmittedLoginForm(data: List(#(String, String)))
}
