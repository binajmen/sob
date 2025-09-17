insert into
  questions (prompt, position)
values
  (
    $1,
    (
      select
        coalesce(max("position"), 0) + 1
      from
        questions
    )
  )
returning
  id;
