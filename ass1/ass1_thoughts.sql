-- On d.cse server:
-- psql mymy -f ass1.sql =======> after changing ass1.sql file
-- select check_q1();
-- select * from q1_expected;
-- select * from check_all();
-- source /localstorage/z5309196/env

-- On local server (PgAdmin4)
-- \! cd to view present working directory
-- \? for help
-- \i C:/users/chris/documents/uni/comsci/comp3311/work/ass1/mymy1.dump
-- \i C:/users/chris/documents/uni/comsci/comp3311/work/ass1/ass1.sql
-- \d to list tables, etc.

-- create or replace view Q1(unswid, name)
-- as
-- select p.unswid, p.name
-- from People as p, Students as s
-- where count(distinct courses) > 4
-- ;
-- Program_enrolments.student = s.id


-- Q1 -------------------------------------------------------------------------------------
    -- ANSWER -----------------------------------------------------------------------------
    WITH temp AS (
        SELECT student, count(distinct program) as pCount
        FROM Program_enrolments
        GROUP BY student
    )
    SELECT p.unswid, p.name
    FROM People p JOIN temp t on (t.student = p.id)
    GROUP BY unswid, name, pCount
    HAVING t.pCount > 4;

    
    select p.unswid, p.name from People as p; -- works so far
    select count(distinct Program_enrolments) from Program_enrolments; -- also works

    WITH temp AS (
        SELECT distinct e.program, p.unswid, p.name, count(e.student) as pCount
        FROM program_enrolments e JOIN people p ON (p.id = e.student)
        GROUP BY unswid, name, program
        ORDER BY name
    )
    SELECT *
    FROM temp
    WHERE temp.pCount > 4;

    select p.unswid, p.name
    from People p
    where exists
        (select e.student
        from Program_enrolments e
        group by e.student
        having count (*) > 4
        )
    ;
        (select count(id)from Program_enrolments as e where e.student = p.id) as count


    from People p join Program_enrolments e on (count > 4)
    where count(e.student) > 4
    -- could do a nested select some stuff as count (count is the number of program_enrolments of a student)

    -- or maybe a join is better but idk if joins can work with this.

    select id from students
    select p.unswid, p.name from People as p; -- works so far
    select count(distinct Program_enrolments) from Program_enrolments; -- also works

    select p.unswid, p.name
    from People p
    where exists
        (select e.student
        from Program_enrolments e
        group by e.student
        having count (*) > 4
        )
    ;
        (select count(id)from Program_enrolments as e where e.student = p.id) as count


    from People p join Program_enrolments e on (count > 4)
    where count(e.student) > 4
    -- could do a nested select some stuff as count (count is the number of program_enrolments of a student)

    -- or maybe a join is better but idk if joins can work with this.

    select id from students

-- Q2 -------------------------------------------------------------------------------------
    WITH temp AS (
        SELECT p.unswid, p.name, count(s.course) AS course_cnt
        FROM People p JOIN Course_staff s on s.staff = p.id
        WHERE s.role = 3004
        GROUP BY unswid, name
    )
    SELECT *
    FROM temp
    WHERE temp.course_cnt = (SELECT MAX(course_cnt) FROM temp);
    -- Alternative solution
    WITH temp AS (
        SELECT p.unswid, p.name, count(s.course) AS course_cnt
        FROM People p JOIN Course_staff s on s.staff = p.id
        WHERE s.role = 3004
        GROUP BY unswid, name
    )
    SELECT *
    FROM temp
    WHERE temp.course_cnt >= ALL(SELECT course_cnt FROM temp);



    -- find beers sold for the highest price
    select beer from sells where price >= all(select price from sells)

    select * from Staff_roles s where s.id = 3004 -- or s.name='Course Tutor' gets u Course Tutor in table;
    select * from Course_staff s where s.role = 3004 order by s.staff;

    select p.unswid, p.name, max(counts) as course_cnt
    from People p join Course_staff s on s.staff = p.id,
        (select count(s.course) as counts
        from Course_staff s join People p on s.staff = p.id
        where s.role = 3004
        group by s.staff
        ) as Counted_courses
    where s.role = 3004
    group by unswid, name
    ; -- cant have nested aggregate functions\
    having count(course) = (select max(count(course)))
    order by course_cnt desc

    select s.course, s.staff, p.unswid, p.name
    from People p join Course_staff s on s.staff = p.id
    where s.role = 3004
    order by s.staff
    ; -- works, just need to implement the count bit now and add it with AND to WHERE

    select s.course, count(s.course) as course_cnt, s.staff, p.unswid, p.name
    from Course_staff s join People p on s.staff = p.id
    where s.role = 3004 group by course, staff, unswid, name
    order by s.staff
    ;

    select p.unswid, p.name, count(s.course) as course_cnt
    from People p join Course_staff s on s.staff = p.id
    where s.role = 3004
    group by unswid, name
    order by course_cnt desc
    Limit 1
    ; -- best one but limits to only one entry so if there are multiple max then gg

    with Counts as (
        select staff, count(course) as course_cnt
        from Course_staff s
        where s.role = 3004
        group by staff
    )
    select p.unswid, p.name, course_cnt
    from People p JOIN Course_staff s on s.staff = p.id, Counts
    where s.role = 3004 AND course_cnt = (select max(course_cnt) from Counts)
    order by course_cnt;


    SELECT * FROM (SELECT p.unswid, p.name, count(s.course) AS course_cnt
        FROM People p JOIN Course_staff s on s.staff = p.id
        WHERE s.role = 3004
        GROUP BY unswid, name) AS temp
    WHERE temp.course_cnt >= ALL(temp.course_cnt);
-- Q3 -------------------------------------------------------------------------------------
    course_enrolments.student = students.id = People.id

    course_enrolments.mark

    course_enrolments.course -> Courses.id
    courses.subject -> subjects.id
    subjects.offeredBy -> orgUnits.id
    orgunits.name = 'School of Law'

    SELECT p.unswid, p.name
    FROM 

    CREATE VIEW CourseMarksAndAverages(course,term,student,mark,avg)
    AS
    SELECT s.code, termName(t.id), e.student, e.mark, avg(mark) OVER (PARTITION BY course)
    FROM CourseEnrolments e
        JOIN Courses c on c.id = e.course
        JOIN Subjects s on s.id = c.subject
        JOIN Terms t on t.id = c.term;
-- Q4 -------------------------------------------------------------------------------------
    -- Answer
    with temp as (
        select DISTINCT p.unswid, p.name, t.name as term, t.id as term_id, s.code
        from course_enrolments e
            join students stu on e.student = stu.id
            join people p on stu.id = p.id
            join courses c on e.course = c.id
            join terms t on c.term = t.id
            join subjects s on c.subject = s.id
        where s.code = 'COMP9020' OR s.code = 'COMP9331' AND stu.stype = 'local'       
    )
    select distinct t1.unswid, t1.name
    from temp t1
    group by unswid, name, term_id
    having count(term_id) > 1;


    course_enrolments.student = students.id = People.id

    course_enrolments.mark

    -- needs the term id to be the same for both subjects
    -- maybe 2 subject tables joined on same term id?

    select id from subjects
    where code = 'COMP9020';


    course_enrolments.course -> Courses.id
    courses.term -> term.id
    courses.subject -> subject.id
    subject.code = 'COMP9020' AND 'COMP9331' -- could use union with subject?
-- Q5 -------------------------------------------------------------------------------------
    -- If there is more than one result, you can choose to show all or any of them.
    -- Min might mean the lowest rate of failure? check expected result to clarify

    -- Check https://webcms3.cse.unsw.edu.au/COMP3311/22T1/forums/2811666 for update on
    -- difference between part a and b.s


    -- Return Terms.name -> Courses.term.name -> Course_enrolments.course & min_fail_rate
    -- Course_enrolments refs Courses.id as course. Courses refs terms.id as term.

    -- Only count students with valid marks (not null)

    -- For all the marks in Course_enrolments.mark, count the ones <50,
    -- then divide by all students in Course_enrolments (Course_enrolments.student)

    -- HINT:======================================================
    -- Course_enrolments table contains enrolment information for all terms
    -- so you can't just count all tuples in the table.

    -- Repeat for all terms course is offered in the timeframe

    -- compute the fail rate of COMP3311 in the term 22T1, the result should be
    -- ( the number of students with mark<50 enrolled in COMP3311 in 22T1 ) /
    -- ( the number of students with not-null mark enrolled in COMP3311 in 22T1 ).

    -- Then get the min

    -- Round the min to nearest 0.0001
    -- (i.e. if minimum fail rate = 0.01, then return 0.0100; if minimum fail rate = 0.01234,
    -- then return 0.0123; if minimum fail rate = 0.02345, then return 0.0235).

    need terms.name and min_fail_rate
    course_enrolments.mark

    course_enrolments.course = courses.id
    course.term = terms.id
    course.subject = subjects.id
    subjects.code = 'COMP3311'



    select e1.student, e2.student
    from course_enrolments e1 join course_enrolments e2 on (e1.student = e2.student)
    where e1.mark < 50 and e1.mark is not null
    group by e1.student, e2.student;

    round (( select count(e1.student) / count(e2.student)

    from course_enrolments e1 join course_enrolments e2 on (e1.student = e2.student)

    where e1.mark < 50 AND e2.mark IS NOT NULL), 4) as fail_rate
    -- result is always 1 because above has joined two tables in the FROM clause
    -- so results in e1 is not always equal to e2

    select b1.name, b2.name
    from Beers b1 join Beers b2 on (b1.brewer =  b2.brewer)
    where b1.name < b2.name;
    -- Above find pairs of beers by same manufacturer

    SELECT name, round (
        (SELECT COUNT(student)
        FROM id_namemark
        WHERE mark < 50 AND name = 'Sem1 2009')::numeric /
            (SELECT count(student)
            FROM id_namemark
            WHERE name = 'Sem1 2009'
            )::numeric,4
        )
    FROM id_namemark
    WHERE name = 'Sem1 2009'
    GROUP BY name;

    SELECT term.name
    FROM Terms
    WHERE term.id = id_result_from_query;

    -- 2 helper views for q5a
    create or replace view total_marks_q5a(term_id, term, count)
    as
    SELECT c.term AS term_id, t.name, count(*)
    FROM course_enrolments e
    JOIN students stu ON e.student = stu.id
    JOIN people p ON stu.id = p.id
    JOIN courses c ON c.id = e.course
    JOIN subjects s ON s.id = c.subject
    JOIN terms t ON t.id = c.term
    WHERE s.code = 'COMP3311' AND 
    e.mark IS NOT NULL AND 
    t.year BETWEEN 2009 AND 2012
    GROUP BY c.term, t.name
    ;
    create or replace view failing_marks_q5a(term_id, term, count)
    as
    SELECT c.term AS term_id, t.name, count(*)
    FROM course_enrolments e
    JOIN students stu ON e.student = stu.id
    JOIN people p ON stu.id = p.id
    JOIN courses c ON c.id = e.course
    JOIN subjects s ON s.id = c.subject
    JOIN terms t ON t.id = c.term
    WHERE s.code = 'COMP3311' AND 
    e.mark < 50 AND 
    t.year BETWEEN 2009 AND 2012
    GROUP BY c.term, t.name
    ;
    -- Q5a
    -- Explanation
        -- Get non-null marks from term and the failing marks from the same term for COMP3311 using helper views
        -- Divide both of these casted as numeric so result is not 0, rounded to 4dp.
    create or replace view Q5a(term, min_fail_rate)
    as
    WITH temp AS (
        SELECT fm.term_id, fm.term, round (cast(fm.count AS numeric) / cast(tm.count AS numeric), 4) AS min_fail_rate
        FROM total_marks_q5a tm JOIN failing_marks_q5a fm ON tm.term_id = fm.term_id
        GROUP BY fm.term_id, fm.term, min_fail_rate
    )
    SELECT term, min_fail_rate
    FROM temp
    WHERE min_fail_rate = (select min(min_fail_rate) FROM temp)
    GROUP BY term, min_fail_rate
    ;
-- Q6 -------------------------------------------------------------------------------------
    create or replace function
        Q6(id integer,code text) returns integer
    as $$
    SELECT e.mark
    FROM course_enrolments e
    JOIN students stu ON e.student = stu.id
    JOIN people p ON stu.id = $1
    JOIN courses c ON c.id = e.course
    JOIN subjects s ON s.id = c.subject
    WHERE s.code = $2 
    $$ language sql;

-- Q7 -------------------------------------------------------------------------------------
    -- e.g. 2019, 'T1'
    -- returns a list of all the postgraduate COMP courses (refers to Subjects.code starting with COMP) offered at the given year and session. 
    -- An postgraduate course is the one whose Subjects.career is PG.
    create or replace function 
        Q7(year integer, session text) returns table (code text)
    as $$
    select subj.code
    from People p
    join Students s on s.id = $1
    join Course_Enrolments ce on ce.student = s.id
    join Courses c on c.id = ce.course
    join Subjects subj on subj.id = c.subject
    join Terms t on t.id = c.term
    where subj.code like '%COMP%' and subj.career = 'PG' and t.year = $1 and t.session = $2
    -- TODO(Ryan): in db term session names are strange like X1, S2. No standard ones like T1 as mentioned in question? 
    --... SQL statements, possibly using other views/functions defined by you ...
    $$ language sql;
-- Q9 -------------------------------------------------------------------------------------
    -- Only consider the direct child group for gid, don't need to consider grandchildren
    -- or great grandchildren groups.