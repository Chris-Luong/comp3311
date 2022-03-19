-- comp3311 22T1 Assignment 1
-- Christopher Luong, March 2022

-- Q1
-- Explanation
    -- Find student's id and number of distinct programs
    -- they enrolled in. Then join People and temp table
    -- to get unswid and name if no. of programs > 4.
create or replace view Q1(unswid, name)
as
WITH temp AS (
    SELECT student, count(distinct program) AS pCount
    FROM Program_enrolments
    GROUP BY student
)
SELECT p.unswid, p.name
FROM People p JOIN temp t ON (t.student = p.id)
GROUP BY unswid, name, pCount
HAVING t.pCount > 4;


-- Q2
-- Explanation
    -- Join tables to get staff only, then filter for tutors only
    -- before getting course_cnt. Then get the details from
    -- temp if they have the most course_cnt (can be multiple).
create or replace view Q2(unswid, name, course_cnt)
as
WITH temp AS (
    SELECT p.unswid, p.name, count(s.course) AS course_cnt
    FROM People p JOIN Course_staff s on s.staff = p.id
    WHERE s.role = 3004
    GROUP BY unswid, name
)
SELECT *
FROM temp
WHERE temp.course_cnt = (SELECT MAX(course_cnt) FROM temp);


-- Q3
-- Explanation
    -- Link up all the tables to get from enrolment to the student id
    -- whilst including the organisation unit to get School of Law.
create or replace view Q3(unswid, name)
as
SELECT distinct p.unswid, p.name
FROM course_enrolments e
    JOIN Students stu ON e.student = stu.id
    JOIN People p ON stu.id = p.id
    JOIN Courses c ON c.id = e.course
    JOIN subjects s ON s.id = c.subject
    JOIN orgUnits o ON s.offeredBy = o.id
WHERE o.name = 'School of Law' AND stu.stype = 'intl' AND e.mark > 85;


-- Q4
-- Explanation
    -- Get all local students doing both courses, then find the ones
    -- doing the courses in the same term by finding duplicate term ids
create or replace view Q4(unswid, name)
as
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


create or replace view COMP3331WithMark(term, counter)
as
select c.term, count(*)
from People p
join Students s on s.id = p.id
join Course_Enrolments ce on ce.student = s.id
join Courses c on c.id = ce.course
join Subjects subj on subj.id = c.subject
join Terms t on t.id = c.term
where subj.code = 'COMP3311' and 
ce.mark is not null and 
t.year between 2009 and 2012
group by c.term
;

create or replace view COMP3331WithFailingMark(term, counter)
as
select c.term, count(*)
from People p
join Students s on s.id = p.id
join Course_Enrolments ce on ce.student = s.id
join Courses c on c.id = ce.course
join Subjects subj on subj.id = c.subject
join Terms t on t.id = c.term
where subj.code = 'COMP3311' and 
ce.mark < 50 and 
t.year between 2009 and 2012
group by c.term
;
-- Q5a
create or replace view Q5a(term, min_fail_rate)
as
select wm.term, wm.count / fm.count as fail_rate
from COMP3331WithMark wm join COMP3331WithFailingMark fm on wm.term = fm.term
group by wm.term
order by fail_rate asc
limit 1
;


-- Q5b
-- create or replace view Q5b(term, min_fail_rate)
-- as
-- --... SQL statements, possibly using other views/functions defined by you ...
-- ;


-- Q6
	Q6(id integer,code text) returns integer
as $$
select ce.mark
from People p
join Students s on s.id = $1
join Course_Enrolments ce on ce.student = s.id
join Courses c on c.id = ce.course
join Subjects subj on subj.id = c.subject
where subj.code = $2 
$$ language sql;


-- Q7
-- 	Q7(year integer, session text) returns table (code text)
-- as $$
-- --... SQL statements, possibly using other views/functions defined by you ...
-- $$ language sql;


-- Q8
-- 	Q8(zid integer) returns setof TermTranscriptRecord
-- as $$
-- --... SQL statements, possibly using other views/functions defined by you ...
-- $$ language plpgsql;


-- Q9
-- 	Q9(gid integer) returns setof AcObjRecord
-- as $$
-- --... SQL statements, possibly using other views/functions defined by you ...
-- $$ language plpgsql;


-- Q10
-- 	Q10(code text) returns setof text
-- as $$
-- --... SQL statements, possibly using other views/functions defined by you ...
-- $$ language plpgsql;

