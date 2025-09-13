update questions
set
  prompt = $2,
  updated_at = now()
where
  id = $1
returning
  *;
