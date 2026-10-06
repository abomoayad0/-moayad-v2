-- public.v2_day_dismissals(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9e69f50bacbb20c487c7a19583f1fe9f
CREATE OR REPLACE FUNCTION public.v2_day_dismissals(p_school uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE(student_id uuid, student_name text, class_ar text, left_at time without time zone, minutes_after integer, threshold text, threshold_ar text, reason_ar text, action_taken text, recorded_role text, guardian_notified boolean)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_school(p_school,'قراءة انصرافات اليوم');
  return query
   select s.id, v2.fn_display_name(s.full_name), v2.grade_ar(e.grade)||' — '||e.section,
    d.left_at, d.minutes_after::int, d.threshold::text,
    (case d.threshold when 'action_30' then 'تجاوز 30 دقيقة' else 'بين 15 و30 دقيقة' end)::text,
    d.reason_ar::text, d.action_taken::text, d.recorded_role::text, d.guardian_notified
   from v2.dismissal_records d
   join v2.students s on s.id=d.student_id
   join v2.enrolments e on e.student_id=s.id and e.status='active'
   where d.school_id=p_school and d.on_date=p_date
   order by d.minutes_after desc;
end $function$
;
