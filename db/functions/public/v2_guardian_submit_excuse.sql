-- public.v2_guardian_submit_excuse(p_student uuid, p_from date, p_to date, p_reason text, p_attachment_name text, p_excuse_item smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d59d48ffb321d68a2feb4ed5fbb73d0c
CREATE OR REPLACE FUNCTION public.v2_guardian_submit_excuse(p_student uuid, p_from date, p_to date, p_reason text, p_attachment_name text DEFAULT NULL::text, p_excuse_item smallint DEFAULT NULL::smallint)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare st text; m text; d text; h text; c text; v uuid;
begin
  perform v2.assert_my_child(p_student,'تقديم عذر');
  if btrim(coalesce(p_reason,''))='' then raise exception 'اكتب سبب الغياب'; end if;
  if p_to < p_from then raise exception 'تاريخ النهاية قبل البداية'; end if;
  v := v2.fn_submit_excuse(p_student,p_from,p_to,'guardian','portal',p_excuse_item,
         p_reason,null,p_attachment_name,current_date);
  return v;
exception when others then
  get stacked diagnostics st=returned_sqlstate, m=message_text, d=pg_exception_detail,
    h=pg_exception_hint, c=pg_exception_context;
  perform v2.fn_log_error(m,'v2_guardian_submit_excuse','بوابة ولي الأمر','تقديم عذر',
    jsonb_build_object('student',p_student,'from',p_from,'to',p_to), st,d,h,c,'bridge',
    case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', m using errcode = st;
end $function$
;
