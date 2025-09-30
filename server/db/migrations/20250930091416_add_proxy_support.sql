-- migrate:up
alter table users add column proxy_id uuid references users(id);

-- migrate:down
alter table users drop column proxy_id;