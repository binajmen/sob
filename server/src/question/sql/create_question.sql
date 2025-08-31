insert into
  questions (poll_id, prompt)
values
  ($1, $2)
returning
  id;
