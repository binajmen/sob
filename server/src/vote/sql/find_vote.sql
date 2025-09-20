select
  *
from
  votes
where
  question_id = $1
  and user_id = $2;

