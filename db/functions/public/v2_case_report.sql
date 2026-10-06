-- public.v2_case_report(p_case uuid, p_opinion text, p_recommend text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 156a4f0d146e7cbf031438728cf66a92
CREATE OR REPLACE FUNCTION public.v2_case_report(p_case uuid, p_opinion text, p_recommend text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare c record; n int; f record; l record; j text; sp text;
        m text; st text; d text; h text; ctx text;
begin
  select * into c from v2.counsel_cases where id=p_case;
  if c.id is null then raise exception 'الحالةُ غيرُ موجودة'; end if;
  if not v2.is_counselor(c.school_id) then
    raise exception 'تقريرُ دراسة الحالة يرفعه الموجّه الطلابيّ'; end if;
  if c.written_at is null then raise exception 'لا يُرفع تقريرٌ قبل أن تُكتب دراسةُ الحالة'; end if;
  if btrim(coalesce(p_opinion,''))='' then raise exception 'اكتب الرأيَ الفنّيّ'; end if;
  if btrim(coalesce(p_recommend,''))='' then raise exception 'اكتب التوصية'; end if;
  if exists (select 1 from v2.counsel_reports where case_id=p_case) then
    raise exception 'رُفع التقريرُ سلفًا — ولا يُرفع مرّتين'; end if;

  select count(*) into n from v2.counsel_sessions where case_id=p_case;
  if n = 0 then raise exception 'لا يُرفع تقريرٌ بلا جلسةِ متابعةٍ واحدةٍ على الأقلّ'; end if;
  select * into f from v2.counsel_sessions where case_id=p_case order by session_no limit 1;
  select * into l from v2.counsel_sessions where case_id=p_case order by session_no desc limit 1;
  sp := to_char(f.held_on,'YYYY-MM-DD')||' — '||to_char(l.held_on,'YYYY-MM-DD');
  j := case when l.response = 'تحسّنٌ ملحوظ' then 'استجاب'
            when l.response = 'تحسّنٌ طفيف' then 'تحسّنٌ غيرُ كافٍ'
            else 'لم يستجب' end;

  insert into v2.counsel_reports(case_id,issued_by,sessions_n,span_ar,last_resp,
      judgement,opinion,recommend)
  values (p_case,v2.current_person(),n,sp,l.response,j,btrim(p_opinion),btrim(p_recommend));

  -- 🔑 هنا تُقفل المعالجة — لا عند كتابة الدراسة
  update v2.counsel_cases set state='تمّت المعالجة' where id=p_case;

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,is_test)
  values (c.school_id,'case_report',current_date,c.student_id,
      'رُفع تقريرُ دراسة الحالة إلى لجنة التوجيه',
      'عن '||n||' جلسة · '||l.response,'counsel_reports',p_case,'staff',
      coalesce(c.is_test,false));
  return jsonb_build_object('ok',true,'sessions',n,'judgement',j,'state','تمّت المعالجة');
exception when others then
  get stacked diagnostics st=returned_sqlstate, m=message_text, d=pg_exception_detail,
    h=pg_exception_hint, ctx=pg_exception_context;
  perform v2.fn_log_error(m,'v2_case_report','التوجيه الطلابي','تقرير دراسة الحالة',
    jsonb_build_object('case',p_case), st,d,h,ctx,'bridge',
    case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', m using errcode = st;
end $function$
;
