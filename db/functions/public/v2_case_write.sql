-- public.v2_case_write(p_case uuid, p_student_view text, p_observed text, p_factors text, p_plan text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2517ade30783745e9c16d93f935c1e85
CREATE OR REPLACE FUNCTION public.v2_case_write(p_case uuid, p_student_view text, p_observed text, p_factors text, p_plan text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare c record; m text; st text; d text; h text; ctx text;
begin
  select * into c from v2.counsel_cases where id=p_case;
  if c.id is null then raise exception 'الحالةُ غيرُ موجودة'; end if;
  if not v2.is_counselor(c.school_id) then
    raise exception 'دراسةُ الحالة للموجّه الطلابيّ وحدَه'; end if;
  if btrim(coalesce(p_student_view,''))='' or btrim(coalesce(p_observed,''))=''
     or btrim(coalesce(p_factors,''))='' or btrim(coalesce(p_plan,''))='' then
    raise exception 'لا تُحفظ الدراسةُ ناقصةً — الحقولُ الأربعةُ مطلوبة'; end if;

  update v2.counsel_cases
     set student_view=btrim(p_student_view), observed=btrim(p_observed),
         factors=btrim(p_factors), plan_ar=btrim(p_plan),
         written_by=v2.current_person(), written_at=now()
   where id=p_case;

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,is_test)
  values (c.school_id,'case_study',current_date,c.student_id,
      'دُرست حالةُ الطالب','سرّيّةٌ عند الموجّه — ويخرج منها التقريرُ وحدَه',
      'counsel_cases',p_case,'counselor_only',coalesce(c.is_test,false));
  return jsonb_build_object('ok',true,'state',c.state);
exception when others then
  get stacked diagnostics st=returned_sqlstate, m=message_text, d=pg_exception_detail,
    h=pg_exception_hint, ctx=pg_exception_context;
  perform v2.fn_log_error(m,'v2_case_write','التوجيه الطلابي','دراسة حالة',
    jsonb_build_object('case',p_case), st,d,h,ctx,'bridge',
    case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', m using errcode = st;
end $function$
;
