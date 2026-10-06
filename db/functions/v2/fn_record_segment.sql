-- v2.fn_record_segment(p_student uuid, p_date date, p_segment text, p_state text, p_by uuid, p_term smallint, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 fde0b56ab7126263247f5899074a4569
CREATE OR REPLACE FUNCTION v2.fn_record_segment(p_student uuid, p_date date, p_segment text, p_state text, p_by uuid DEFAULT NULL::uuid, p_term smallint DEFAULT 1, p_note text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare v_school uuid; v_year uuid; v_id uuid;
begin
  if not exists (select 1 from v2.day_segments where key=p_segment) then
    raise exception 'فترة غير معروفة: %', p_segment; end if;
  select e.school_id, e.year_id into v_school, v_year from v2.enrolments e
   where e.student_id=p_student and e.status='active' order by e.created_at desc limit 1;
  insert into v2.period_attendance(school_id,year_id,term_no,student_id,on_date,period_no,segment,state,note,teacher_id)
  values (v_school,v_year,p_term,p_student,p_date,null,p_segment,p_state,p_note,p_by)
  returning id into v_id;
  return v_id;
end $function$
;
