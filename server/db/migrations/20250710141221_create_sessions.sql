-- migrate:up
create table sessions (
  id uuid primary key default uuid_generate_v4 (),
  name text not null,
  created_at timestamp not null default now (),
  updated_at timestamp not null default now ()
);

-- migrate:down
drop table sessions;
