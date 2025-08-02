insert into
  polls (name)
values
  ($1)
returning
  id;
