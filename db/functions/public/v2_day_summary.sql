-- public.v2_day_summary(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 475520f8be0665532ce50941d1beccf5
CREATE OR REPLACE FUNCTION public.v2_day_summary(p_school uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE(day_kind text, hijri text, enrolled integer, present integer, absent integer, late integer, permitted integer, unrecorded integer, missed_assembly integer, closed boolean, reopened boolean)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_school(p_school,'قراءة ملخّص اليوم');
  return query select * from v2.fn_day_summary(p_school,p_date);
end $function$
;
