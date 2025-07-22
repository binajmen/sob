select u.*
from users u
inner join sessions s on u.id = s.user_id
where s.id = $1;
