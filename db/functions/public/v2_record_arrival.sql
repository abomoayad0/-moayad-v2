-- public.v2_record_arrival(p_student uuid, p_date date, p_arrived time without time zone, p_decision text, p_term smallint, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4d9a45f86e7547e491bc7fca7d5713e3
CREATE OR REPLACE FUNCTION public.v2_record_arrival(p_student uuid, p_date date, p_arrived time without time zone, p_decision text DEFAULT 'enter_class'::text, p_term smallint DEFAULT NULL::smallint, p_note text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; t smallint;
begin
  if p_arrived is null then raise exception 'اكتب وقتَ الوصول'; end if;
  perform v2.assert_my_student(p_student,'تسجيل الوصول المتأخر');
  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' order by e.created_at desc limit 1;
  t := coalesce(p_term, v2.fn_term_of(sc,p_date));
  return v2.fn_record_arrival(p_student,p_date,p_arrived,p_decision,t,v2.current_person(),p_note);
end $function$
;
