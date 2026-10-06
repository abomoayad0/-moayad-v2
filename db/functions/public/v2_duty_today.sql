-- public.v2_duty_today(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d10d87f3fa10286e56face85e7336f8b
CREATE OR REPLACE FUNCTION public.v2_duty_today(p_school uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE(zone_key text, zone_ar text, segment text, min_staff smallint, staff_n integer, staff_ar text, is_enough boolean)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_school(p_school,'قراءة جدول المناوبة');
  return query select * from v2.fn_duty_today(p_school,p_date);
end $function$
;
