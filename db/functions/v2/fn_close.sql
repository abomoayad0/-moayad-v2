-- v2.fn_close(p_school text, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e90227cd31dfea4909dd4e2119934d7c
CREATE OR REPLACE FUNCTION v2.fn_close(p_school text, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE("المقيدون" integer, "المرصودون" integer, "غياب" integer, "تأخر" integer, "مشتق" integer, "لم_يُرصد" integer, "أحداث" integer)
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid;
begin
  select id into sc from v2.schools where name_ar like '%'||p_school||'%' limit 1;
  if sc is null then raise exception 'لا مدرسة باسم يشبه: %', p_school; end if;
  return query select * from v2.fn_close_day(sc, p_date, null);
end $function$
;
