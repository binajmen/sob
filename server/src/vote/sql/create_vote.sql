insert into
  votes (question_id, user_id, vote)
values
  ($1, $2, $3)
on conflict (question_id, user_id) do update
set
  vote = excluded.vote,
  updated_at = now()
returning
  *;

