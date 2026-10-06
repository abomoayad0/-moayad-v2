-- public.v2_case_report_card(p_student uuid, p_problem integer)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 05e7c788ae70f07220f6dce6798ba46d
CREATE OR REPLACE FUNCTION public.v2_case_report_card(p_student uuid, p_problem integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  perform v2.assert_my_student(p_student,'تقرير دراسة الحالة');
  select jsonb_build_object(
    'issued_on',rp.issued_on,
    'issued_by',v2.fn_display_name(pe.full_name),
    'sessions',rp.sessions_n,'span',rp.span_ar,
    'last_response',rp.last_resp,'judgement',rp.judgement,
    'opinion',rp.opinion,'recommend',rp.recommend,
    'note','ملخّصٌ — ولا يحمل نصَّ الجلسات ولا دراسةَ الحالة، فهما سرّيّتان عند الموجّه')
  into r
  from v2.counsel_reports rp
  join v2.counsel_cases c on c.id=rp.case_id
  left join v2.people pe on pe.id=rp.issued_by
  where c.student_id=p_student and c.problem_id=p_problem
  order by rp.issued_on desc limit 1;
  return coalesce(r, jsonb_build_object('note','لم يُرفع تقريرُ دراسة الحالة بعد — واللجنةُ تبحث على أساسه · ص٢٠'));
end $function$
;
