-- public.v2_counsel_board(p_school uuid, p_state text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 71d03592b82fcd8f5a88e4dfcb182982
CREATE OR REPLACE FUNCTION public.v2_counsel_board(p_school uuid, p_state text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.is_counselor(p_school) then
    raise exception 'مؤشّرُ متابعة الحالات للموجّه الطلابيّ وحدَه — ولا يُفتح لغيره ولو كانت صلاحيّتُه كاملة';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'case', c.id, 'student', v2.fn_display_name(st.full_name),
      'student_id', c.student_id,
      'problem', p.text_ar, 'degree', p.degree_no, 'indicator', 'السلوك',
      'records', (select count(*) from v2.behavior_records br
                   where br.student_id=c.student_id and br.problem_id=c.problem_id
                     and br.year_id=c.year_id and br.status<>'voided'),
      'opened_on', c.opened_on, 'state', c.state,
      'studied', (c.written_at is not null),
      'sessions', (select count(*) from v2.counsel_sessions s where s.case_id=c.id),
      'reported', exists (select 1 from v2.counsel_reports rp where rp.case_id=c.id)
    ) order by c.opened_on desc),'[]'::jsonb)
  into r from v2.counsel_cases c
  join v2.students st on st.id=c.student_id
  join v2.conduct_problems p on p.id=c.problem_id
  where c.school_id=p_school and (p_state is null or c.state=p_state);
  return r;
end $function$
;
