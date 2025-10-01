delete from users
where
  id = $1
  and is_admin = false
returning
  *;