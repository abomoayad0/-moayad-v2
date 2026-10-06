-- public.v2_day_classes(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d9939acb7ea1ace45d540ff7e09fbb9f
CREATE OR REPLACE FUNCTION public.v2_day_classes(p_school uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE(grade smallint, section text, label_ar text, enrolled integer, recorded integer, unrecorded integer, present integer, absent integer, late integer, permitted integer, missed_assembly integer, is_done boolean)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_school(p_school,'قراءة فصول اليوم');
  return query select * from v2.fn_day_classes(p_school,p_date);
end $function$
;
