-- COMP3311
-- Assignment 1
-- Vinh Pham (z5310912)
-- 18-03-2021

-- Helper views

/*
A view which shows the total premium of each enforced policy.
 */
create or replace view prems(brand, vid, pno, premium) as
    select ii.brand, ii.id, pol.pno, sum(rr.rate) from insured_item ii
    join policy pol on (pol.id = ii.id)
    join coverage c on (c.pno = pol.pno)
    join rating_record rr on (rr.coid = c.coid)
    where pol.status = 'E'
    and rr.status = 'A'
    group by ii.brand, ii.id, pol.pno;

/*
A view which shows the maximum premium for each brand.
*/
create or replace view max_prems(brand, premium) as
    select brand, max(premium) from prems
    group by brand;

/*
A view which shows the staff who were involved in enforced policies.
*/
create or replace view worked(s_by, r_by, uw_by) as
    select pol.sid, ub.sid, rb.sid from policy pol
    join underwriting_record ur on (ur.pno = pol.pno)
    join underwritten_by ub on (ub.urid = ur.urid)
    join coverage c on (c.pno = pol.pno)
    join rating_record rr on (rr.coid = c.coid)
    join rated_by rb on (rb.rid = rr.rid)
    where pol.status = 'E';

/*
A view which shows the staff who were involved in specific policies.
*/
create or replace view staffed(pno, ptype, s_by, r_by, uw_by) as 
    select distinct pol.pno, pol.ptype, pol.sid, rb.sid, ub.sid from policy pol
    join underwriting_record ur on (ur.pno = pol.pno)
    join underwritten_by ub on (ub.urid = ur.urid)
    join coverage c on (c.pno = pol.pno)
    join rating_record rr on (rr.coid = c.coid)
    join rated_by rb on (rb.rid = rr.rid)
    where pol.status = 'E';

/*
A view which shows the turnaround time of each policy.
*/
create or replace view turnaround(pno, dur) as
    select pol.pno, (max(ub.wdate) - min(rb.rdate)) as dur from policy pol
    join underwriting_record ur on (ur.pno = pol.pno)
    join underwritten_by ub on (ub.urid = ur.urid)
    join coverage c on (c.pno = pol.pno)
    join rating_record rr on (rr.coid = c.coid)
    join rated_by rb on (rb.rid = rr.rid)
    where pol.status = 'E'
    group by pol.pno;

/*
A view which shows all the id's of staff members who only sold policies for one brand.
*/
create or replace view one_brand(sid) as
    select pol.sid from policy pol
    join insured_item ii on (ii.id = pol.id)
    where pol.status = 'E'
    group by pol.sid
    having count(distinct ii.brand) = 1;

/*
A view which shows all the id's of clients who hold policies for all brands.
*/
create or replace view all_brand(cid) as 
    select ib.cid from insured_by ib
    join policy pol on (pol.pno = ib.pno)
    join insured_item ii on (ii.id = pol.id)
    group by ib.cid
    having count(distinct ii.brand) = (select count(distinct brand) from insured_item);

-- Helper functions

/*
A function which returns a list of all staff involved with a specific policy.
*/
create or replace function staffinvolved(_pno integer) returns setof integer as 
$$
declare
    _staff record;
begin
    for _staff in (
        select pol.sid from policy pol where pol.pno = _pno

        union

        select ub.sid from underwritten_by ub
        join underwriting_record ur on (ur.urid = ub.urid)
        where ur.pno = _pno

        union

        select rb.sid from rated_by rb
        join rating_record rr on (rr.rid = rb.rid)
        join coverage c on (rr.coid = c.coid)
        where c.pno = _pno
    ) loop
        return next _staff;
    end loop;
end;
$$ language plpgsql;

-- Q1
create or replace view Q1(pid, firstname, lastname) as 
    select p.pid, p.firstname, p.lastname from person p
    where p.pid not in (
        select pid from client
        union
        select pid from staff
    )
    order by p.pid asc;

-- Q2
create or replace view Q2(pid, firstname, lastname) as
    select p.pid, p.firstname, p.lastname from person p
    where p.pid not in (
        select c.pid from client c
        join insured_by ib on (ib.cid = c.cid)
        join policy pol on (pol.pno = ib.pno)
        where pol.status = 'E'
    )
    order by p.pid asc;

-- Q3
create or replace view Q3(brand, vid, pno, premium) as
    select p.brand, p.vid, p.pno, mp.premium from prems p
    join max_prems mp on (p.brand = mp.brand)
    where p.premium = mp.premium
    order by
        p.brand asc,
        p.vid asc,
        p.pno asc; 

-- Q4
create or replace view Q4(pid, firstname, lastname) as
    select p.pid, p.firstname, p.lastname from person p
    join staff s on (s.pid = p.pid)
    where s.sid not in (
        select s_by as sid from worked
        union
        select r_by as sid from worked
        union
        select uw_by as sid from worked
    )
    order by p.pid asc;

-- Q5
create or replace view Q5(suburb, npolicies) as
    select upper(p.suburb), count(ib.pno) from person p
    join client c on (c.pid = p.pid)
    join insured_by ib on (ib.cid = c.cid)
    join policy pol on (pol.pno = ib.pno)
    where pol.status = 'E'
    group by p.suburb
    order by
        count asc,
        p.suburb asc;

-- Q6
create or replace view Q6(pno, ptype, pid, firstname, lastname) as
    select st.pno, st.ptype, p.pid, p.firstname, p.lastname from staffed st
    join staff s on (s.sid = st.s_by)
    join person p on (p.pid = s.pid)
    where st.pno in (
        select pno from policy
        where status = 'E'
        except
        select pno from staffed
        group by pno
        having count(*) > 1
    )
    and st.s_by = st.r_by 
    and st.r_by = st.uw_by
    order by st.pno asc;

-- Q7
create or replace view Q7(pno, ptype, effectivedate, expirydate, agreedvalue) as
    select pol.pno, pol.ptype, pol.effectivedate, pol.expirydate, pol.agreedvalue from policy pol
    join turnaround t on (t.pno = pol.pno)
    where t.dur = (select max(dur) from turnaround)
    order by pol.pno asc;

-- Q8
create or replace view Q8(pid, name, brand) as
    select distinct p.pid, p.firstname||' '||p.lastname, ii.brand from person p
    join staff s on (s.pid = p.pid)
    join policy pol on (pol.sid = s.sid)
    join insured_item ii on (ii.id = pol.id)
    where s.sid in (
        select * from one_brand
    )
    order by p.pid asc;
    
-- Q9
create or replace view Q9(pid, name) as
    select p.pid, p.firstname||' '||p.lastname from person p
    join client c on (c.pid = p.pid)
    where c.cid in (
        select * from all_brand
    )
    order by p.pid asc;

-- Q10
create or replace function staffcount(_pno integer) returns integer as
$$
declare
    _count integer;
    _policy policy%rowtype;
begin
    select * into _policy from policy pol
    where pol.pno = _pno;

    if _policy is null then
        return 0;
    end if;

    _count := (select count(*) from staffinvolved(_pno));
    return _count;
end;
$$ language plpgsql;

-- Q11
create or replace procedure renew(_pno integer)
language plpgsql
as $$
declare
    _policy policy%rowtype;
    _ccpolicy policy%rowtype;
    _new_pno integer;
    _new_exp_date date;
    _cov record;
    _new_cov integer;
begin
    select * into _policy from policy pol
    where pol.pno = _pno;

    select * into _ccpolicy from policy pol
    where pol.status = 'E'
    and pol.effectivedate <= current_date
    and current_date < pol.expirydate
    and pol.id = _policy.id
    and pol.ptype = _policy.ptype
    and pol.pno <> _pno;

    if _policy is null or _ccpolicy is not null then
        return;
    end if;

    select max(pno) + 1 into _new_pno from policy;
    _new_exp_date := current_date + (_policy.expirydate - _policy.effectivedate);
    insert into policy values(_new_pno, _policy.ptype, 'D', current_date, _new_exp_date, _policy.agreedvalue, _policy.comments, _policy.sid, _policy.id);

    if _policy.status = 'E' and _policy.effectivedate <= current_date and current_date < _policy.expirydate then
        update policy set expirydate = current_date where pno = _pno;
    end if;

    for _cov in (select * from coverage c where c.pno = _pno)
    loop
        select max(coid) + 1 into _new_cov from coverage;
        insert into coverage values(_new_cov, _cov.cname, _cov.maxamount, _cov.comments, _new_pno);
    end loop;

    return;
end;
$$;

-- Q12
create or replace function checkAgent() returns trigger as $$
declare
    _agent integer;
    _client integer;
begin
    select s.pid into _agent from staff s
    where s.sid = new.sid;

    for _client in (
        select c.pid from client c
        join insured_by ib on (ib.cid = c.cid)
        where ib.pno = new.pno
    ) loop
        if _agent = _client then
            raise exception 'Agent cannot be the client of the policy';
        end if;
    end loop;
    return new;
end;
$$ language plpgsql;

create or replace function checkClient() returns trigger as $$
declare
    _agent integer;
    _client integer;
    _rater integer;
    _underwriter integer;
begin
    select c.pid into _client from client c
    where c.cid = new.cid;

    select s.pid into _agent from staff s
    join policy pol on (pol.sid = s.sid)
    where pol.pno = new.pno;

    if _client = _agent then
        raise exception 'Client cannot be the agent of their own policy.';
    end if;

    for _rater in (
        select s.pid from staff s
        join rated_by rb on (rb.sid = s.sid)
        join rating_record rr on (rr.rid = rb.rid)
        join coverage c on (c.coid = rr.coid)
        where c.pno = new.pno
    )
    loop
        if _client = _rater then
            raise exception 'Client cannot be the rater of their own policy.';
        end if;
    end loop;

    for _underwriter in (
        select s.pid from staff s
        join underwritten_by ub on (ub.sid = s.sid)
        join underwriting_record ur on (ur.urid = ub.urid)
        where ur.pno = new.pno
    ) loop
        if _client = _underwriter then
            raise exception 'Client cannot be the underwriter of their own policy.';
        end if;
    end loop;

    return new;
end;
$$ language plpgsql;

create or replace function checkRater() returns trigger as $$
declare
    _client integer;
    _rater integer;
begin
    select s.pid into _rater from staff s
    where s.sid = new.sid;

    for _client in (
        select c.pid from client c
        join insured_by ib on (ib.cid = c.cid)
        join coverage c on (c.pno = ib.pno)
        join rating_record rr on (rr.coid = c.coid)
        join rated_by rb on (rb.rid = rr.rid)
        where rb.rid = new.rid
    ) loop
        if _rater = _client then
            raise exception 'Rater cannot be the client of the policy.';
        end if; 
    end loop;
    return new;
end;
$$ language plpgsql;

create or replace function checkUnderwriter() returns trigger as $$
declare
    _client integer;
    _underwriter integer;
begin
    select s.pid into _underwriter from staff s
    where s.sid = new.sid;

    for _client in (
        select c.pid from client c
        join insured_by ib on (ib.cid = c.cid)
        join underwriting_record ur on (ur.pno = ib.pno)
        join underwritten_by ub on (ub.urid = ur.urid)
        where ub.urid = new.urid
    ) loop
        if _underwriter = _client then
            raise exception 'Underwriter cannot be the client if the policy.';
        end if;
    end loop;
    return new;
end;
$$ language plpgsql;

create trigger checkAgent after insert or update
on policy for each row execute procedure checkAgent();

create trigger checkClient after insert or update
on insured_by for each row execute procedure checkClient();

create trigger checkRater after insert or update
on rated_by for each row execute procedure checkRater();

create trigger checkUnderwriter after insert or update
on underwritten_by for each row execute procedure checkUnderwriter();

