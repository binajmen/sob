insert into users (email, password_hash) values ($1, $2) returning id;
