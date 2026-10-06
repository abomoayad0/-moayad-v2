-- v2.fn_pending_excuses(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 594c9b783c2b1e2d0d909d8e48fc524e
CREATE OR REPLACE FUNCTION v2.fn_pending_excuses(p_school uuid)
 RETURNS TABLE(claim_id uuid, student_id uuid, student_name text, grade smallint, section text, class_ar text, from_date date, to_date date, from_h text, to_h text, days integer, submitted_on date, submitted_h text, by_whom text, channel text, reason_text text, attachment_name text, working_days_used smallint, window_verdict text, decision text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select c.id, s.id, v2.fn_display_name(s.full_name), e.grade, e.section,
   v2.grade_ar(e.grade)||' — '||e.section,
   c.from_date, c.to_date, v2.fn_to_hijri(c.from_date), v2.fn_to_hijri(c.to_date),
   (c.to_date - c.from_date + 1)::int,
   c.submitted_on, v2.fn_to_hijri(c.submitted_on), c.submitted_by, c.channel,
   c.reason_text, c.attachment_name, c.working_days_used, c.window_verdict, c.decision
  from v2.absence_excuse_claims c
  join v2.students s on s.id=c.student_id
  join v2.enrolments e on e.student_id=s.id and e.status='active'
  where e.school_id=p_school and c.decision='pending'
  order by c.submitted_on, c.from_date
$function$
;
