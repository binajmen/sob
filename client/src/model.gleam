import router.{type Route}
import routes/sign_in

pub type Model {
  Model(route: Route, lang: String, page: Page)
}

pub type Page {
  Index
  SignIn(sign_in.Model)
  // SignUp(sign_up.Model)
}

pub type Msg {
  UserNavigatedTo(route: Route)
  SignInMsg(sign_in.Msg)
}
