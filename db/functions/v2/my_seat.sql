-- v2.my_seat(p_school uuid, p_committee text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 cb03043a3d088b710b3190d6cda16ee9
CREATE OR REPLACE FUNCTION v2.my_seat(p_school uuid, p_committee text)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select m.seat_role from v2.committee_members m
   where m.committee_key=p_committee and m.school_id=p_school
     and m.person_id=v2.current_person() and m.ended_on is null limit 1;
$function$
;
