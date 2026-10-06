-- public.v2_my_census(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2f393410eb772396d310e76ef76fc603
CREATE OR REPLACE FUNCTION public.v2_my_census(p_school uuid)
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
      'census',c.id,'student',v2.fn_display_name(s.full_name),'student_id',s.id,
      'assigned_at',c.assigned_at::date,'due',c.due_on,
      'days_ar',v2.ar_num(c.days),
      'late',(c.due_on < current_date),
      'state',c.state,'returned_why',c.returned_why,
      'by',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=c.assigned_by),
      'problem',(select cp.text_ar from v2.behavior_records br
                  join v2.conduct_problems cp on cp.id=br.problem_id where br.id=c.record_id))
      order by c.due_on),'[]'::jsonb)
  into r from v2.behavior_census c join v2.students s on s.id=c.student_id
  where c.school_id=p_school and c.assigned_to=me and c.state in ('مكلَّف','مُعاد');
  return r;
end $function$
;
