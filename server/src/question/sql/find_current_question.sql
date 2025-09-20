select 
  q.id,
  q.prompt,
  q.position,
  q.created_at,
  q.updated_at
from poll_state ps
left join questions q on ps.current_question_id = q.id
where ps.id = 1
  and ps.status = 'voting'
  and q.id is not null;