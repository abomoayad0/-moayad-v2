-- public.v2_session_add(p_case uuid, p_on date, p_minutes smallint, p_discussed text, p_response text, p_next text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 045c47861908182f1b588f33e947e15f
CREATE OR REPLACE FUNCTION public.v2_session_add(p_case uuid, p_on date, p_minutes smallint, p_discussed text, p_response text, p_next text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare c record; n smallint; m text; st text; d text; h text; ctx text;
begin
  select * into c from v2.counsel_cases where id=p_case;
  if c.id is null then raise exception 'الحالةُ غيرُ موجودة'; end if;
  if not v2.is_counselor(c.school_id) then
    raise exception 'جلساتُ المتابعة للموجّه الطلابيّ'; end if;
  if c.written_at is null then
    raise exception 'لا تُفتح جلسةٌ قبل أن تُكتب دراسةُ الحالة — فالجلسةُ تدخّلٌ والتدخّلُ بعد الدراسة'; end if;
  if btrim(coalesce(p_discussed,''))='' then raise exception 'اكتب ما نُوقش في الجلسة'; end if;
  if btrim(coalesce(p_next,''))='' then raise exception 'اكتب الخطوةَ التالية'; end if;
  if coalesce(p_on,current_date) > current_date then
    raise exception 'لا تُقيَّد جلسةٌ في تاريخٍ لم يأتِ بعد'; end if;
  if p_response is null or btrim(p_response)='' then
    raise exception 'اختر مدى الاستجابة: تحسّنٌ ملحوظ · تحسّنٌ طفيف · السلوكُ مستمرّ · تراجُع'; end if;
  if p_response not in ('تحسّنٌ ملحوظ','تحسّنٌ طفيف','السلوكُ مستمرّ','تراجُع') then
    raise exception 'مدى الاستجابة أربعةٌ لا غير: تحسّنٌ ملحوظ · تحسّنٌ طفيف · السلوكُ مستمرّ · تراجُع'; end if;

  select coalesce(max(session_no),0)+1 into n from v2.counsel_sessions where case_id=p_case;
  insert into v2.counsel_sessions(case_id,session_no,held_on,minutes,discussed,response,
      next_step,by_person)
  values (p_case,n,coalesce(p_on,current_date),p_minutes,btrim(p_discussed),p_response,
      btrim(p_next),v2.current_person());

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,is_test)
  values (c.school_id,'counselor_session',coalesce(p_on,current_date),c.student_id,
      'جلسةُ متابعةٍ رقم '||n,'سرّيّةٌ عند الموجّه — '||p_response,
      'counsel_sessions',p_case,'counselor_only',coalesce(c.is_test,false));
  return jsonb_build_object('ok',true,'session',n);
exception when others then
  get stacked diagnostics st=returned_sqlstate, m=message_text, d=pg_exception_detail,
    h=pg_exception_hint, ctx=pg_exception_context;
  perform v2.fn_log_error(m,'v2_session_add','التوجيه الطلابي','جلسة متابعة',
    jsonb_build_object('case',p_case), st,d,h,ctx,'bridge',
    case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', m using errcode = st;
end $function$
;
