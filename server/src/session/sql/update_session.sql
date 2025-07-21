update
  sessions
set
  user_id = $2
where
  id = $1
