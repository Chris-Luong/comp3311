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
    from movies m, aliases a
    where title ~* 'mothra'
    order by rating desc, start_year, title;

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