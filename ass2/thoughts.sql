-- Q1
    select role, id, name, count(name) as count
    from names n join crew_roles c on n.id = c.name_id
    where c.role = 'director'
    group by id, name, role
    order by count desc, name;

    select *
    from crew_roles
    where role = 'director';

-- Q2
    select m.rating, m.title, m.start_year
    from movies m
    where title ~* 'mothra'
    order by rating desc, start_year, title;

    select m.title, a.local_title, a.region, a.language, a.extra_info
    from movies m join aliases a on a.movie_id = m.id
    where m.id = -- the actual id %s
    order by a.ordering;


    aliases as a, a.movie_id = m.id
    if count of above == 1,
    then only print title and year + "was also released as", with list aliases of movie
    aliases get title, region if exists, and language if exists in brackets, comma separated
    if no region/language, put a.extra_info in brackets.
    If all 3 !exist, no brackets after alias.local_title
    order by "ordering" attribute in aliases

    e.g.
    2001: A Space Odyssey (1968) was also released as
    '2001' (region: XWW, language: en)
    'Two Thousand and One: A Space Odyssey' (region: US)
    '2001: Odisea del espacio' (region: UY)
    '2001: Een zwerftocht in de ruimte' (region: NL)

    no aliases: print "[Title] [(Year)] has no alternative releases"

    if two titles are exactly the same, dw in this question since count > 1
-- Q3
    list cast and crew for ONE movie, given name/partial name and optional Year cl arg
    check expected to find how to display (capitalise first letter and replace _ with space)

    if found ONE movie, print title and year of movie. Then list principal actors with roles.
    then list principal crew members and roles
    sort by principals.ordering, then role name for both actors and crew members

    principals table: movie_id, ordering, name_id
    acting_roles table: movie_id, name_id, played (some character)
    crew_roles table: movie_id, name_id, role

    if partial name matches multiple movies, print like q2.

    -- Gets all principal actors in correct order
    select distinct p.ordering, m.title, m.start_year, n.name, a.played, n.id, m.id as m_id
    from principals p join names n on n.id = p.name_id
    join movies m on p.movie_id = m.id
    join acting_roles a on m.id = a.movie_id and a.name_id = p.name_id
    where m.title ~* 'Avatar'
    order by p.ordering, a.played;

    -- Gets correct actors with 'played' but not orderd by ordering
    select distinct m.title, m.start_year, n.name, a.played, n.id, m.id as m_id
    from acting_roles a join names n on n.id = a.name_id
    join movies m on m.id = a.movie_id
    join principals p on p.movie_id = m.id
    where m.title ~* 'Avatar'
    order by start_year;
    -- order by p.ordering, a.played;

    -- Gets all principal actors and crew (in correct order for actors), but wrong 'played' column
    select distinct p.ordering, m.title, m.start_year, n.name, a.played, n.id, m.id as m_id
    from principals p join names n on n.id = p.name_id
    join movies m on p.movie_id = m.id
    join acting_roles a on m.id = a.movie_id
    where m.title ~* 'Avatar'
    order by start_year;
    

    select p.ordering, m.title, n.name
    from principals p join names n on n.id = p.name_id
    join movies m on m.id = p.movie_id
    where m.id = 10499549 and n.id = 20941777;

    select p.ordering, n.name
    from principals p join names n on n.id = p.name_id
    where n.id = 20735442;

    select n.name, c.role
    from names n join crew_roles c on n.id = c.name_id
    where n.id = 20941777;



    select distinct m.title, m.start_year, n.name, c.role, p.ordering
    from crew_roles c join names n on n.id = c.name_id
    join movies m on m.id = c.movie_id
    join principals p on p.movie_id = m.id
    where title ~* 'Avatar'
    order by p.ordering, c.role;
    -- order by start_year;

    select distinct n.name, a.played, m.title
    from acting_roles a join names n on n.id = a.name_id
    join movies m on m.id = a.movie_id
    join principals p on p.movie_id = a.movie_id
    where n.name = 'Sam Worthington';

    with unordered as (
        select distinct m.title, m.start_year, n.name, a.played, n.id
        from acting_roles a join names n on n.id = a.name_id
        join movies m on m.id = a.movie_id
        join principals p on p.movie_id = m.id
        where m.title ~* 'Avatar')
    select *, p.ordering
    from unordered join principals p on p.name_id = unordered.id
    order by ordering;
-- Q4
    select distinct n.name, m.title, m.rating
    from movies m join principals p on p.movie_id = m.id
    join names n on n.id = p.name_id
    where n.name ~* 'spike lee'
    group by n.name, m.title, m.rating;


    with temp as 
    (select distinct m.rating
    from movies m join principals p on p.movie_id = m.id
    join names n on n.id = p.name_id
    where n.name ~* 'spike lee')

    select round(cast(avg(rating) as decimal),1) from temp;
