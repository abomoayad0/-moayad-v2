-- public.v2_record_period(p_student uuid, p_period smallint, p_state text, p_date date, p_minutes smallint, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 494896e62f19cdf5c6fa0faa7cec4d64
CREATE OR REPLACE FUNCTION public.v2_record_period(p_student uuid, p_period smallint, p_state text, p_date date DEFAULT CURRENT_DATE, p_minutes smallint DEFAULT NULL::smallint, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare st text; m text; d text; h text; c text;
begin
  return v2.fn_record_period(p_student,p_period,p_state,p_date,p_minutes,p_note,v2.current_person());
exception when others then
  get stacked diagnostics st=returned_sqlstate, m=message_text, d=pg_exception_detail,
    h=pg_exception_hint, c=pg_exception_context;
  perform v2.fn_log_error(m,'v2_record_period','بطاقة الحصة','رصد حضور الحصة',
    jsonb_build_object('student',p_student,'period',p_period,'state',p_state,'date',p_date),
    st,d,h,c,'bridge', case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', m using errcode = st;
end $function$
;
