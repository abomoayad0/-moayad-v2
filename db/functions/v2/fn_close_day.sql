-- v2.fn_close_day(p_school uuid, p_date date, p_by uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 210541bd50c6a576caac9d1b9d57dbb2
CREATE OR REPLACE FUNCTION v2.fn_close_day(p_school uuid, p_date date, p_by uuid DEFAULT NULL::uuid)
 RETURNS TABLE("المقيدون" integer, "المرصودون" integer, "غياب" integer, "تأخر" integer, "مشتق" integer, "لم_يُرصد" integer, "أحداث" integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_role(array['deputy_students','deputy'],'إقفال اليوم');
  return query select * from v2.fn_close_day_inner(p_school,p_date,p_by);
end $function$
;
