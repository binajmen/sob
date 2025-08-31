-- migrate:up
create table polls (
  id uuid primary key default uuid_generate_v4 (),
  name text not null,
  created_at timestamp not null default now(),
  updated_at timestamp not null default now()
);

create table questions (
  id uuid primary key default uuid_generate_v4 (),
  poll_id uuid not null references polls (id) on delete cascade,
  prompt text not null,
  created_at timestamp not null default now(),
  updated_at timestamp not null default now()
);

create table votes (
  id uuid primary key default uuid_generate_v4 (),
  question_id uuid not null references questions (id) on delete cascade,
  user_id uuid not null references users (id) on delete cascade,
  vote text not null,
  created_at timestamp not null default now(),
  updated_at timestamp not null default now()
);

-- migrate:down
drop table votes;

drop table questions;

drop table polls;
