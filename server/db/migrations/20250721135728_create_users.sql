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

-- Insert fake admin user
INSERT INTO users (email, password_hash, first_name, last_name, is_admin) 
VALUES ('admin@example.com', 'XohImNooBHFR0OVvjcYpJ3NgPQ1qq73WKhHvch0VQtg', 'Admin', 'User', true);

-- migrate:down
drop table users;
