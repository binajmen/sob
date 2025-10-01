select
  u.*
from
  users u
  left join votes v on u.id = v.user_id
  and v.question_id = $1
where
  v.user_id is null
  and u.is_admin = false
order by
  u.first_name asc,
  u.last_name asc;

