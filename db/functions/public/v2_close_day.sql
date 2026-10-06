-- public.v2_close_day(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 df846ceaa263174dec008f00d13eca61
CREATE OR REPLACE FUNCTION public.v2_close_day(p_school uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE(enrolled integer, recorded integer, absent integer, late integer, derived integer, unrecorded integer, events integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare st text; m text; d text; h text; c text;
begin
  perform v2.assert_my_school(p_school,'إقفال اليوم');
  return query select * from v2.fn_close_day(p_school,p_date,v2.current_person());
exception when others then
  get stacked diagnostics st=returned_sqlstate, m=message_text, d=pg_exception_detail,
    h=pg_exception_hint, c=pg_exception_context;
  perform v2.fn_log_error(m,'v2_close_day','قرارات الوكيل','إقفال اليوم',
    jsonb_build_object('school',p_school,'date',p_date), st,d,h,c,'bridge',
    case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', m using errcode = st;
end $function$
;
