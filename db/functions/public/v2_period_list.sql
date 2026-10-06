-- public.v2_period_list(p_section uuid, p_period smallint, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 345519c27a0d081cb93ab463f19c57f7
CREATE OR REPLACE FUNCTION public.v2_period_list(p_section uuid, p_period smallint, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE(student_id uuid, student_no text, display_name text, class_ar text, day_state text, day_state_ar text, period_state text, period_state_ar text, minutes_late smallint, note text, day_status text, practices_today integer)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid;
begin
  select school_id into sc from v2.class_sections where id=p_section;
  perform v2.assert_my_school(sc,'قراءة قائمة الحصة');
  return query select * from v2.fn_period_list(p_section,p_period,p_date);
end $function$
;
