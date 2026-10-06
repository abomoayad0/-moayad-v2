-- public.v2_day_list(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2d91c1df2a5086b63014243a6db00a26
CREATE OR REPLACE FUNCTION public.v2_day_list(p_school uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE(student_id uuid, student_no text, full_name text, display_name text, grade smallint, section text, state text, state_ar text, assembly_state text, assembly_ar text, arrived_at time without time zone, minutes_late smallint, recorded_role text, source text, day_status text, has_permit boolean, permit_decision text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_school(p_school,'قراءة قائمة اليوم');
  return query select * from v2.fn_day_list(p_school,p_date);
end $function$
;
