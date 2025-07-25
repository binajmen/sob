import formal/form.{type Form}

pub type SignInFormData {
  SignInFormData(email: String, password: String)
}

pub fn sign_in_form() -> Form(SignInFormData) {
  form.new({
    use email <- form.field("email", form.parse_email)
    use password <- form.field(
      "password",
      form.parse_string |> form.check_string_length_more_than(8),
    )
    form.success(SignInFormData(email:, password:))
  })
}

pub type SignUpFormData {
  SignUpFormData(email: String, password: String)
}

pub fn sign_up_form() -> Form(SignUpFormData) {
  form.new({
    use email <- form.field("email", form.parse_email)
    use password <- form.field("password", form.parse_string)
    form.success(SignUpFormData(email:, password:))
  })
}
