delete from polls
where
  id = $1
returning
  *;
