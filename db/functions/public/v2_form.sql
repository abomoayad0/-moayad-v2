-- public.v2_form(p_form smallint, p_student uuid, p_ref uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e118dbd508b114008364f5406fed8cc4
CREATE OR REPLACE FUNCTION public.v2_form(p_form smallint, p_student uuid, p_ref uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare st text; m text; d text; h text; c text;
begin
  return v2.fn_form(p_form,p_student,p_ref);
exception when others then
  get stacked diagnostics st=returned_sqlstate, m=message_text, d=pg_exception_detail,
    h=pg_exception_hint, c=pg_exception_context;
  perform v2.fn_log_error(m,'v2_form','النماذج','فتح نموذج',
    jsonb_build_object('form',p_form,'student',p_student,'ref',p_ref), st,d,h,c,'bridge',
    case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', m using errcode = st;
end $function$
;
