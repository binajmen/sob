insert into
  users (first_name, last_name, proxy_id)
values
  ($1, $2, $3)
returning
  id;