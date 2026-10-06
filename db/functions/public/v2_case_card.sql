-- public.v2_case_card(p_case uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 015b5fc23890de426c2250075a05b793
CREATE OR REPLACE FUNCTION public.v2_case_card(p_case uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare c record; r jsonb;
begin
  select * into c from v2.counsel_cases where id=p_case;
  if c.id is null then raise exception 'الحالةُ غيرُ موجودة'; end if;
  if not v2.is_counselor(c.school_id) then
    raise exception 'دراسةُ الحالة سرّيّةٌ عند الموجّه الطلابيّ'; end if;

  select jsonb_build_object(
    'case', to_jsonb(c) - 'school_id',
    'student', (select jsonb_build_object('name',v2.fn_display_name(s.full_name),
         'no',s.student_no) from v2.students s where s.id=c.student_id),
    'guardian', (select jsonb_build_object('name',v2.fn_display_name(g.full_name),
         'relation',g.relation) from v2.guardians g
         where g.student_id=c.student_id and g.is_primary limit 1),
    'problem', (select jsonb_build_object('text',p.text_ar,'degree',p.degree_no,
         'source',p.source_page) from v2.conduct_problems p where p.id=c.problem_id),
    'records', (select coalesce(jsonb_agg(jsonb_build_object(
           'on',br.occurred_on,'no',br.occurrence_no,'step',br.step_no,
           'by',v2.fn_display_name(pe.full_name),'place',br.place,'note',br.note)
         order by br.occurrence_no),'[]'::jsonb)
       from v2.behavior_records br left join v2.people pe on pe.id=br.recorded_by
       where br.student_id=c.student_id and br.problem_id=c.problem_id
         and br.year_id=c.year_id and br.status<>'voided'),
    'deducted', (select coalesce(-sum(points),0) from v2.behavior_ledger l
       where l.student_id=c.student_id and l.kind='deduction'),
    'sessions', (select coalesce(jsonb_agg(jsonb_build_object(
           'no',s.session_no,'on',s.held_on,'minutes',s.minutes,
           'discussed',s.discussed,'response',s.response,'next',s.next_step)
         order by s.session_no desc),'[]'::jsonb)
       from v2.counsel_sessions s where s.case_id=c.id),
    'report', (select to_jsonb(rp) from v2.counsel_reports rp where rp.case_id=c.id limit 1),
    'note','لا حقلَ للأسرة ولا للحالة الصحّيّة — لا سندَ نظاميًّا يأذن بجمعها'
  ) into r;
  return r;
end $function$
;
