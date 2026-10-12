-- v2.cover_candidates(p_school uuid, p_weekday smallint, p_period smallint, p_date date, p_subject text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 be3bf782b855e08cf762c87a341cbbab
CREATE OR REPLACE FUNCTION v2.cover_candidates(p_school uuid, p_weekday smallint, p_period smallint, p_date date DEFAULT NULL::date, p_subject text DEFAULT NULL::text)
 RETURNS TABLE(person_id uuid, person_ar text, basis text, covers_term integer, covers_day integer, teach_n integer, subject_match boolean, blocked_ar text, ord integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
with ru as (select * from v2.cover_rules_of(p_school)),
tn as (select v2.fn_term_of(p_school, coalesce(p_date, current_date)) term_no),
pool as (
  select distinct t.person_id pid, 'standby'::text bas
    from v2.timetable t, tn
   where t.school_id = p_school and t.weekday = p_weekday and t.period_no = p_period
     and t.slot_kind = 'standby' and t.person_id is not null
     and (t.term_no is null or t.term_no = tn.term_no)
  union
  select pe.id, 'free'
    from v2.people pe
    join v2.assignments a on a.person_id = pe.id and a.school_id = p_school and a.ended_on is null
    cross join ru
   where ru.allow_teaching_free and pe.status = 'active' and a.post_key = 'subject_teacher'
     and not exists (select 1 from v2.timetable t2, tn
                      where t2.school_id = p_school and t2.weekday = p_weekday
                        and t2.period_no = p_period and t2.person_id = pe.id
                        and (t2.term_no is null or t2.term_no = tn.term_no))
),
m as (
  select p.pid, p.bas,
    (select count(*) from v2.period_covers c, tn
      where c.school_id = p_school and c.cover_person = p.pid
        and c.voided_at is null and c.term_no = tn.term_no)::int ct,
    (select count(*) from v2.period_covers c2
      where p_date is not null and c2.school_id = p_school and c2.cover_person = p.pid
        and c2.voided_at is null and c2.on_date = p_date)::int cd,
    (select count(*) from v2.timetable t3
      where t3.school_id = p_school and t3.person_id = p.pid and t3.slot_kind = 'teaching')::int tn2,
    (p_subject is not null and exists (
       select 1 from v2.timetable t4 where t4.school_id = p_school and t4.person_id = p.pid
         and t4.slot_kind = 'teaching' and t4.subject_ar = p_subject)) sm
  from pool p
),
b as (
  select m.*, case
    when p_date is not null and exists (
         select 1 from v2.staff_absences sa
          where sa.school_id = p_school and sa.person_id = m.pid and sa.on_date = p_date
            and sa.voided_at is null
            and (sa.from_period is null or p_period >= sa.from_period)
            and (sa.to_period   is null or p_period <= sa.to_period))
      then 'غائبٌ هذا اليوم'
    when (p_date is not null and exists (
           select 1 from v2.effective_periods(p_school, m.pid, p_date) e9
            where e9.period_no = p_period))
      or (p_date is null and exists (
           select 1 from v2.timetable t5, tn
            where t5.school_id = p_school and t5.weekday = p_weekday and t5.period_no = p_period
              and t5.person_id = m.pid and t5.slot_kind in ('teaching','activity')
              and (t5.term_no is null or t5.term_no = tn.term_no)))
      then 'عنده حصّةٌ في هذا الوقت'
    when p_date is not null and exists (
         select 1 from v2.period_covers c3
          where c3.school_id = p_school and c3.on_date = p_date and c3.period_no = p_period
            and c3.cover_person = m.pid and c3.voided_at is null)
      then 'مُسنَدٌ إليه في هذه الحصّة'
    when p_date is not null and m.cd >= (select max_per_day from ru)
      then 'بلغ حدَّه الأعلى اليوم'
    else null end blk
  from m
)
select b.pid, v2.fn_display_name(pe.full_name), b.bas, b.ct, b.cd, b.tn2, b.sm, b.blk,
  case when b.blk is not null then null else
    (rank() over (partition by (b.blk is null) order by
       case when b.bas = 'standby' then 0 else 1 end,
       case when (select prefer_same_subject from ru) and b.sm then 0 else 1 end,
       b.ct asc, b.tn2 asc, pe.full_name))::int end
from b join v2.people pe on pe.id = b.pid
order by case when b.blk is null then 0 else 1 end,
         case when b.bas = 'standby' then 0 else 1 end, b.ct, b.tn2, pe.full_name
$function$
;
