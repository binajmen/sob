select
  q.id,
  q.prompt,
  count(
    case
      when v.vote = 'yes' then 1
    end
  ) as yes_count,
  count(
    case
      when v.vote = 'no' then 1
    end
  ) as no_count,
  count(
    case
      when v.vote = 'blank' then 1
    end
  ) as blank_count
from
  questions q
  left join votes v on q.id = v.question_id
where
  q.id = $1
group by
  q.id,
  q.prompt;
