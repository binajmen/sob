select
  id,
  email,
  first_name,
  last_name,
  is_admin,
  created_at,
  updated_at,
  proxy_id
from
  users
order by
  first_name asc,
  last_name asc;