-- v2.next_incoming_serial(p_school uuid, p_year uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c718f175eeb5d791da093dde45647918
CREATE OR REPLACE FUNCTION v2.next_incoming_serial(p_school uuid, p_year uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare n integer;
begin
  perform pg_advisory_xact_lock(hashtext('v2.incoming_mail:'||coalesce(p_school::text,'-')));
  select coalesce(max(serial_no),0) + 1 into n from v2.incoming_mail
   where school_id = p_school and year_id is not distinct from p_year;
  return n;
end $function$
;
