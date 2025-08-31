update polls
set
  name = $2,
  updated_at = now()
where
  id = $1
returning
  *;
