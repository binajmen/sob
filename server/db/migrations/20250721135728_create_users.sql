-- migrate:up
create table users (
  id uuid primary key default uuid_generate_v4 (),
  email text not null unique,
  password_hash text not null,
  created_at timestamp not null default now (),
  updated_at timestamp not null default now ()
);

-- migrate:down
drop table users;
