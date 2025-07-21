-- migrate:up
create table sessions (
  id uuid primary key default uuid_generate_v4 (),
  user_id uuid not null references users (id) on delete cascade,
  created_at timestamp not null default now (),
  updated_at timestamp not null default now ()
);

-- migrate:down
drop table sessions;
