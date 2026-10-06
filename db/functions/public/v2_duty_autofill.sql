-- public.v2_duty_autofill(p_school uuid, p_weekday smallint, p_zone text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b155be33170d6f170a784108824e1cbd
CREATE OR REPLACE FUNCTION public.v2_duty_autofill(p_school uuid, p_weekday smallint, p_zone text)
 RETURNS TABLE("أُسند" text, "نصابه" integer, "مناوباته" integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_school(p_school,'توزيع جدول المناوبة');
  return query select * from v2.fn_duty_autofill(p_school,p_weekday,p_zone);
end $function$
;
