-- migrate:up
create table poll_state (
  id integer primary key default 1,
  current_question_id uuid references questions (id) on delete set null,
  status text not null default 'waiting' check (status in ('waiting', 'voting', 'results', 'finished')),
  updated_at timestamp not null default now()
);

-- Ensure only one row can exist
create unique index idx_poll_state_singleton on poll_state (id);

-- Insert the initial state
insert into poll_state (id, status) values (1, 'waiting');

-- migrate:down
drop table poll_state;