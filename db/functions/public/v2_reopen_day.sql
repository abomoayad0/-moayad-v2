-- public.v2_reopen_day(p_school uuid, p_date date, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8b71d421fc0d3c369e77ce97b0affdb0
CREATE OR REPLACE FUNCTION public.v2_reopen_day(p_school uuid, p_date date, p_reason text)
 RETURNS TABLE(behavior_voided integer, cases_voided integer, deductions_restored integer, events_cancelled integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_school(p_school,'إعادة فتح اليوم');
  return query select * from v2.fn_reopen_day(p_school,p_date,p_reason,v2.current_person());
end $function$
;
