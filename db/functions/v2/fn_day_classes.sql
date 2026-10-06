-- v2.fn_day_classes(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7e54e8bb0c7429b893c2b4984a81ca93
CREATE OR REPLACE FUNCTION v2.fn_day_classes(p_school uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE(grade smallint, section text, label_ar text, enrolled integer, recorded integer, unrecorded integer, present integer, absent integer, late integer, permitted integer, missed_assembly integer, is_done boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
with l as (select * from v2.fn_day_list(p_school,p_date))
select grade, section, v2.grade_ar(grade)||' — '||section,
 count(*)::int,
 count(*) filter (where state <> 'unrecorded')::int,
 count(*) filter (where state = 'unrecorded')::int,
 count(*) filter (where state='present')::int,
 count(*) filter (where state='absent')::int,
 count(*) filter (where state='late')::int,
 count(*) filter (where state='permitted')::int,
 count(*) filter (where assembly_state in ('missed_inside','late_inside'))::int,
 (count(*) filter (where state='unrecorded') = 0)
from l group by grade, section order by grade, section;
$function$
;
