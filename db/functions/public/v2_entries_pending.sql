-- public.v2_entries_pending(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8c883637a92dec132052d7948fb1e810
CREATE OR REPLACE FUNCTION public.v2_entries_pending(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare me uuid; r jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  me := v2.current_person();
  select coalesce(jsonb_agg(jsonb_build_object(
      'entry',x.id,'opp',o.id,'merit',m.text_ar,'when',o.when_ar,
      'student',v2.fn_display_name(s.full_name),'student_id',s.id,
      'what',x.what_ar,'evidence',x.evidence_desc,'evidence_path',x.evidence_name,
      'filed_at',x.filed_at,
      'mine', (o.held_by = me),
      'delegated_to_me', (x.delegated_to = me),
      'delegate_note', x.delegate_note)
      order by x.filed_at),'[]'::jsonb)
  into r
  from v2.merit_entries x
  join v2.merit_opportunities o on o.id=x.opp_id
  join v2.conduct_merits m on m.id=o.merit_id
  join v2.students s on s.id=x.student_id
  where o.school_id=p_school
    and x.filed_at is not null and x.verdict is null
    and (o.held_by = me or x.delegated_to = me
         or v2.my_grant() in ('owner','admin'));
  return r;
end $function$
;
