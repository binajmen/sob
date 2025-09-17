insert into
  questions (prompt)
values
  ($1)
returning
  id;
