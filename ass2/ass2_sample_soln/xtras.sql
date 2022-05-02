-- COMP3311 22T1 Ass2 ... extra database definitions
-- add any views or functions you need to this file

drop view if exists movie_count cascade;
create or replace view movie_count(people, mv_cnt) as
select count(*), n.name 
from crew_roles c
join names n on c.name_id = n.id
join movies m on c.movie_id = m.id
where c.role = 'director'
group by n.name
order by count(*) desc, n.name asc;

drop function if exists personal_rate cascade;
create or replace
    function personal_rate(name_id int) returns numeric
as $$
    select round(avg(m.rating)::numeric, 1)
    from principals p
    join movies m on p.movie_id = m.id
    where p.name_id = $1
$$ language sql;

drop function if exists get_top3 cascade;
create or replace
    function get_top3(_name_id int) returns setof text
as $$
    SELECT mg.genre
    FROM principals p
    join movies m on p.movie_id = m.id
    join movie_genres mg on mg.movie_id = m.id
    where p.name_id = _name_id
    group by mg.genre
    order by count(*) desc
    limit 3
$$ language sql;
