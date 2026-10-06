-- public.v2_queue_messages(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 220b55a84b7a8c659b60d95127c3d994
CREATE OR REPLACE FUNCTION public.v2_queue_messages(p_school uuid DEFAULT NULL::uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE("جُهّز" integer, "بلا_جوال" integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_school(p_school,'تجهيز الرسائل');
  return query select * from v2.fn_queue_messages(p_school,p_date);
end $function$
;
