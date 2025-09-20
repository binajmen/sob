UPDATE poll_state 
SET 
  current_question_id = NULL,
  status = $1,
  updated_at = now()
WHERE id = 1;