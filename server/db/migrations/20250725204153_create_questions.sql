-- migrate:up
create table questions (
  id uuid primary key default uuid_generate_v4 (),
  prompt text not null,
  position integer not null,
  created_at timestamp not null default now(),
  updated_at timestamp not null default now()
);

create table votes (
  id uuid primary key default uuid_generate_v4 (),
  question_id uuid not null references questions (id) on delete cascade,
  user_id uuid not null references users (id) on delete cascade,
  vote text not null,
  created_at timestamp not null default now(),
  updated_at timestamp not null default now(),
  unique (question_id, user_id)
);

-- Insert fake question
INSERT INTO questions (prompt, position) 
VALUES ('What is your favorite programming language?', 1);

-- migrate:down
drop table votes;

drop table questions;
