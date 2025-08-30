-- migrate:up
create table users (
  id uuid primary key default uuid_generate_v4 (),
  email text unique,
  password_hash text,
  first_name text,
  last_name text,
  is_admin boolean not null default false,
  created_at timestamp not null default now(),
  updated_at timestamp not null default now()
);

-- migrate:down
drop table users;
