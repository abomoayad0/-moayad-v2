-- public.v2_record_dismissal(p_student uuid, p_date date, p_left time without time zone, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1c4a048e3696150c99eb72ecd8e7f891
CREATE OR REPLACE FUNCTION public.v2_record_dismissal(p_student uuid, p_date date, p_left time without time zone, p_reason text DEFAULT NULL::text)
 RETURNS TABLE(minutes_after integer, threshold text, action_taken text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid;
begin
  perform v2.assert_my_student(p_student,'رصد تأخر الانصراف');
  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' order by e.created_at desc limit 1;
  return query select * from v2.fn_record_dismissal(p_student,p_date,p_left,p_reason,
    v2.fn_term_of(sc,p_date), v2.current_person());
end $function$
;
