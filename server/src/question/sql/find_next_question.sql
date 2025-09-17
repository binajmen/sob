select
  q.id,
  q.prompt,
  q.position,
  q.created_at,
  q.updated_at
from
  questions q
  left join votes v on q.id = v.question_id
where
  v.question_id is null
order by
  q.position asc
limit
  1;
