-- public.v2_period_summary(p_section uuid, p_period smallint, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 45d2274f0e032a797b76e7c1a562b2e1
CREATE OR REPLACE FUNCTION public.v2_period_summary(p_section uuid, p_period smallint, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE(enrolled integer, recorded integer, unrecorded integer, present integer, absent integer, late integer, permitted integer, subject_ar text, teacher_ar text, starts_at time without time zone, ends_at time without time zone, is_done boolean)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid;
begin
  select school_id into sc from v2.class_sections where id=p_section;
  perform v2.assert_my_school(sc,'قراءة ملخّص الحصة');
  return query select * from v2.fn_period_summary(p_section,p_period,p_date);
end $function$
;
