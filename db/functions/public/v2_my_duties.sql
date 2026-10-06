-- public.v2_my_duties(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 87056305cfc712ef060728e4bbb2d69f
CREATE OR REPLACE FUNCTION public.v2_my_duties(p_school uuid)
 RETURNS TABLE(weekday smallint, weekday_ar text, zone_ar text, segment text, kind text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_school(p_school,'قراءة مناوبتي');
  return query select * from v2.fn_my_duties(p_school);
end $function$
;
