select
  *
from
  questions
where
  poll_id = $1
order by
  created_at asc;
