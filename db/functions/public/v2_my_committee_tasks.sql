-- public.v2_my_committee_tasks(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 511acb24878e6501bd5eb98348793764
CREATE OR REPLACE FUNCTION public.v2_my_committee_tasks(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare me uuid; r jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  me := v2.current_person();
  if me is null then raise exception 'لا حسابَ فعّالٌ لك'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'item',i.id,'meeting',m.id,'meeting_no',m.meeting_no,'held_on',m.held_on,
      'committee',(select label_ar from v2.committees where key=m.committee_key),
      'title',i.title_ar,'decision',i.decision_ar,'recommend',i.recommend_ar,
      'due',i.due_on,
      'late', (i.due_on is not null and i.due_on < current_date),
      'days_left', case when i.due_on is null then null else i.due_on - current_date end,
      'student',(select v2.fn_display_name(s.full_name) from v2.students s where s.id=i.student_id),
      'student_id', i.student_id,
      'carried', (i.carried_from is not null))
      order by i.due_on nulls last, m.held_on),'[]'::jsonb)
  into r
  from v2.meeting_items i
  join v2.committee_meetings m on m.id=i.meeting_id
  where m.school_id=p_school and m.status='معتمد'
    and i.outcome='أُقرّ' and i.owner_person=me and i.done_at is null;
  return r;
end $function$
;
