-- public.v2_task_done(p_task uuid, p_ev jsonb)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 89407a646b54df2ad69a89e0afcccfee
CREATE OR REPLACE FUNCTION public.v2_task_done(p_task uuid, p_ev jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare st text; m text; d text; h text; c text;
begin
  return v2.fn_task_done(p_task, p_ev);
exception when others then
  get stacked diagnostics st=returned_sqlstate, m=message_text, d=pg_exception_detail,
    h=pg_exception_hint, c=pg_exception_context;
  perform v2.fn_log_error(m,'v2_task_done','المخالفات السلوكية','إغلاق مهمّة',
    jsonb_build_object('task',p_task,'ev',p_ev), st,d,h,c,'bridge',
    case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', m using errcode = st;
end $function$
;
