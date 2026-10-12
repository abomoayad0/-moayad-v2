-- v2.teaching_staff(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4c38e3d4fd3ab4f60217d86ef00aef22
CREATE OR REPLACE FUNCTION v2.teaching_staff(p_school uuid)
 RETURNS SETOF uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select distinct t.person_id from v2.timetable t
   where t.school_id = p_school and t.person_id is not null
     and t.slot_kind in ('teaching','activity')
$function$
;
