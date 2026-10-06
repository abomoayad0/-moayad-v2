-- public.v2_record_assembly(p_student uuid, p_date date, p_state text, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 45b58d2d60a5ccf91e381b281086c2ff
CREATE OR REPLACE FUNCTION public.v2_record_assembly(p_student uuid, p_date date, p_state text, p_term smallint DEFAULT NULL::smallint)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; t smallint; st text; m text; d text; h text; c text;
begin
  perform v2.assert_my_student(p_student,'رصد الاصطفاف');
  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' order by e.created_at desc limit 1;
  t := coalesce(p_term, v2.fn_term_of(sc,p_date));
  return v2.fn_record_assembly(p_student,p_date,p_state,t,v2.current_person());
exception when others then
  get stacked diagnostics st=returned_sqlstate, m=message_text, d=pg_exception_detail,
    h=pg_exception_hint, c=pg_exception_context;
  perform v2.fn_log_error(m,'v2_record_assembly','رصد اليوم','رصد الاصطفاف',
    jsonb_build_object('student',p_student,'date',p_date,'state',p_state), st,d,h,c,'bridge',
    case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', m using errcode = st;
end $function$
;
