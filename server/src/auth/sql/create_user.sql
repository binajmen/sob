insert into
  users (email, password_hash, first_name, last_name)
values
  ($1, $2, $3, $4)
returning
  id;
