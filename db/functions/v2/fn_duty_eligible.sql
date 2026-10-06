-- v2.fn_duty_eligible(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 75b0a4d9cd416e177cd6090dd936fc99
CREATE OR REPLACE FUNCTION v2.fn_duty_eligible(p_school uuid)
 RETURNS TABLE(person_id uuid, person_ar text, post_ar text, periods integer, duties_now integer, excluded_ar text, priority integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
with staff as (
  select distinct pe.id, pe.full_name, pe.post_key, pe.is_seconded_partial
  from v2.people pe join v2.assignments a on a.person_id=pe.id
  where a.school_id=p_school and a.ended_on is null and pe.status='active'),
load as (select s.id, coalesce((select count(*) from v2.timetable t
   where t.person_id=s.id and t.slot_kind='teaching'),0)::int n from staff s),
d as (select s.id, coalesce((select count(*) from v2.duty_roster r
   where r.person_id=s.id and r.school_id=p_school and r.ends_on is null),0)::int n from staff s),
x as (select s.id,
  case when exists (select 1 from v2.assignments a2 where a2.person_id=s.id and a2.ended_on is null
         and a2.post_key in ('principal','deputy','deputy_students','deputy_academic','deputy_school',
                             'deputy_academic_school','deputy_school_students'))
       then 'مدير أو وكيل — مستثنى بنصّ ض01'
       when s.is_seconded_partial then 'منتدب انتداباً جزئياً — مستثنى بنصّ ض01'
       when s.post_key = 'guard' then 'حارس — ليس من ملاك المدرسة'
       else null end e from staff s)
select s.id, v2.fn_display_name(s.full_name), v2.role_ar(s.post_key),
  l.n, dd.n, x.e,
  case when x.e is not null then null
       else (rank() over (order by l.n asc, dd.n asc))::int end
from staff s join load l on l.id=s.id join d dd on dd.id=s.id join x on x.id=s.id
order by case when x.e is not null then 1 else 0 end, l.n, dd.n
$function$
;
