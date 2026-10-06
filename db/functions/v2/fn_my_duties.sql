-- v2.fn_my_duties(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ed542397c84775da2c1a39c167b7faa2
CREATE OR REPLACE FUNCTION v2.fn_my_duties(p_school uuid)
 RETURNS TABLE(weekday smallint, weekday_ar text, zone_ar text, segment text, kind text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
select r.weekday, r.weekday_ar, z.label_ar, z.segment, r.kind
from v2.duty_roster r join v2.duty_zones z on z.id=r.zone_id
where r.school_id=p_school and r.person_id = v2.current_person() and r.ends_on is null
order by r.weekday, z.label_ar
$function$
;
