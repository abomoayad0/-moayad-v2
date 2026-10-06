-- public.v2_duty_eligible(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d2377a42a8030ba8f0adf4f2f495ebac
CREATE OR REPLACE FUNCTION public.v2_duty_eligible(p_school uuid)
 RETURNS TABLE(person_id uuid, person_ar text, post_ar text, periods integer, duties_now integer, excluded_ar text, priority integer)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_school(p_school,'قراءة أولوية المناوبة');
  return query select * from v2.fn_duty_eligible(p_school);
end $function$
;
