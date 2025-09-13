delete from questions
where
  id = $1
returning
  *;