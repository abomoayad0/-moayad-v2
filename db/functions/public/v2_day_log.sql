-- public.v2_day_log(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e9bdc3a3f19f11c7b18bcaf3c3a8807f
CREATE OR REPLACE FUNCTION public.v2_day_log(p_school uuid, p_date date)
 RETURNS TABLE(kind text, student_name text, grade smallint, section text, class_ar text, title_ar text, body_ar text, needs_action boolean, action_ar text, channels text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_school(p_school,'قراءة سجل وقائع اليوم');
  return query
   select ev.kind, coalesce(v2.fn_display_name(s.full_name),'—'), e.grade, e.section,
     case when e.grade is null then '—' else v2.grade_ar(e.grade)||' — '||e.section end,
     ev.title_ar, ev.body_ar, ev.needs_action, ev.action_ar,
     coalesce((select string_agg(distinct d.channel,' · ') from v2.event_deliveries d where d.event_id=ev.id),'—')
   from v2.events ev
   left join v2.students s on s.id=ev.student_id
   left join v2.enrolments e on e.student_id=s.id and e.status='active'
   where ev.school_id=p_school and ev.on_date=p_date
   order by ev.kind, 2;
end $function$
;
