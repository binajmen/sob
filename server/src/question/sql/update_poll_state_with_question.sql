UPDATE poll_state 
SET 
  current_question_id = $1,
  status = $2,
  updated_at = now()
WHERE id = 1;