-- v2.cover_fairness(p_school uuid, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ecdbb8dd72ad653cb0d933426f9c8faf
CREATE OR REPLACE FUNCTION v2.cover_fairness(p_school uuid, p_term smallint DEFAULT NULL::smallint)
 RETURNS TABLE(person_ar text, person_id uuid, standby_n integer, teach_n integer, covers_n integer, last_on date)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
with tn as (select coalesce(p_term, v2.fn_term_of(p_school, current_date)) term_no),
st as (select distinct pe.id, pe.full_name
         from v2.people pe
         join v2.assignments a on a.person_id = pe.id and a.school_id = p_school and a.ended_on is null
        where pe.status = 'active'
          and (exists (select 1 from v2.timetable t where t.school_id = p_school and t.person_id = pe.id)
               or exists (select 1 from v2.period_covers c where c.school_id = p_school and c.cover_person = pe.id)))
select v2.fn_display_name(st.full_name), st.id,
  (select count(*) from v2.timetable t1 where t1.school_id = p_school and t1.person_id = st.id
     and t1.slot_kind = 'standby')::int,
  (select count(*) from v2.timetable t2 where t2.school_id = p_school and t2.person_id = st.id
     and t2.slot_kind = 'teaching')::int,
  (select count(*) from v2.period_covers c1, tn where c1.school_id = p_school and c1.cover_person = st.id
     and c1.voided_at is null and c1.term_no = tn.term_no)::int,
  (select max(c2.on_date) from v2.period_covers c2 where c2.school_id = p_school
     and c2.cover_person = st.id and c2.voided_at is null)
from st
order by 5 asc, 3 desc, st.full_name
$function$
;
