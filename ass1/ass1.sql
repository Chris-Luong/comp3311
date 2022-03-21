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
WITH temp AS (
    SELECT DISTINCT p.unswid, p.name, t.name AS term, t.id AS term_id, s.code
    FROM course_enrolments e
        JOIN students stu ON e.student = stu.id
        JOIN people p ON stu.id = p.id
        JOIN courses c ON e.course = c.id
        JOIN terms t ON c.term = t.id
        JOIN subjects s ON c.subject = s.id
    WHERE s.code = 'COMP9020' OR s.code = 'COMP9331' AND stu.stype = 'local'       
)
SELECT DISTINCT t1.unswid, t1.name
FROM temp t1
GROUP BY unswid, name, term_id
HAVING count(term_id) > 1;


-- 2 helper views for q5a
create or replace view total_marks_q5a(term_id, term, count)
as
SELECT c.term AS term_id, t.name, count(*)
FROM course_enrolments e
JOIN students stu ON e.student = stu.id
JOIN people p ON stu.id = p.id
JOIN courses c ON c.id = e.course
JOIN terms t ON t.id = c.term
JOIN subjects s ON s.id = c.subject
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


-- 2 helper views for q5b
create or replace view total_marks_q5b(term_id, term, count)
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
t.year BETWEEN 2016 AND 2019
GROUP BY c.term, t.name
;
create or replace view failing_marks_q5b(term_id, term, count)
as
SELECT c.term AS term_id, t.name, count(*)
FROM course_enrolments e
JOIN students stu ON e.student = stu.id
JOIN people p ON stu.id = p.id
JOIN courses c ON c.id = e.course
JOIN terms t ON t.id = c.term
JOIN subjects s ON s.id = c.subject
WHERE s.code = 'COMP3311' AND 
e.mark < 50 AND 
t.year BETWEEN 2016 AND 2019
GROUP BY c.term, t.name
;
-- Q5b
create or replace view Q5b(term, min_fail_rate)
as
WITH temp AS (
    SELECT fm.term_id, fm.term, round (cast(fm.count AS numeric) / cast(tm.count AS numeric), 4) AS min_fail_rate
    FROM total_marks_q5b tm JOIN failing_marks_q5b fm ON tm.term_id = fm.term_id
    GROUP BY fm.term_id, fm.term, min_fail_rate
)
SELECT term, min_fail_rate
FROM temp
WHERE min_fail_rate = (select min(min_fail_rate) FROM temp)
GROUP BY term, min_fail_rate
;


-- Q6
-- Explanation
    -- Get a student's mark for course given subject code and student id
    -- Will return NULL if code or id is invalide due to JOINs
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


-- Q7
-- Explanation
    -- Get course starting with course code COMP in a given year and session
create or replace function
	Q7(year integer, session text) returns table (code text)
as $$ 
SELECT DISTINCT s.code
FROM courses c
JOIN terms t ON t.id = c.term
JOIN subjects s ON s.id = c.subject
WHERE s.code LIKE '%COMP%' AND s.career = 'PG' AND t.year = $1 AND t.session = $2
$$ language sql;


-- Q8
-- create or replace function
-- 	Q8(zid integer) returns setof TermTranscriptRecord
-- as $$
-- --... SQL statements, possibly using other views/functions defined by you ...
-- $$ language plpgsql;


-- Q9
-- create or replace function
-- 	Q9(gid integer) returns setof AcObjRecord
-- as $$
-- --... SQL statements, possibly using other views/functions defined by you ...
-- $$ language plpgsql;


-- Q10
-- create or replace function
-- 	Q10(code text) returns setof text
-- as $$
-- --... SQL statements, possibly using other views/functions defined by you ...
-- $$ language plpgsql;

