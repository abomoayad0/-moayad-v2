-- v2.fn_form_auto(p_form smallint, p_doc jsonb)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 814b3b438e288f8d6d3d8457a150352c
CREATE OR REPLACE FUNCTION v2.fn_form_auto(p_form smallint, p_doc jsonb)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
select coalesce(jsonb_object_agg(s.key, v), '{}'::jsonb)
from v2.form_schema s
cross join lateral (select case s.key
  when 'student_name'  then p_doc#>>'{student,name}'
  when 'class_ar'      then p_doc#>>'{student,class_ar}'
  when 'grade_ar'      then p_doc#>>'{student,grade_ar}'
  when 'student_no'    then p_doc#>>'{student,student_no}'
  when 'national_id'   then p_doc#>>'{student,national_id}'
  when 'birth_h'       then p_doc#>>'{student,birth_h}'
  when 'stage_ar'      then p_doc->>'stage_ar'
  when 'school_ar'     then p_doc->>'school'
  when 'guardian_name' then p_doc#>>'{guardians,0,name}'
  when 'counselor_ar'  then p_doc->>'counselor_ar'
  when 'teacher_ar'    then p_doc->>'teacher_ar'
  when 'problem_ar'    then p_doc#>>'{record,problem_ar}'
  when 'degree_ar'     then case when p_doc#>>'{record,degree_no}' is null then null
                                 else 'الدرجة '||(p_doc#>>'{record,degree_no}') end
  when 'weekday'       then p_doc#>>'{record,weekday_ar}'
  when 'occurred_h'    then nullif(p_doc#>>'{record,occurred_h}','')||' هـ'
  when 'actions_text'  then p_doc->>'actions_text'
  when 'days_n'        then p_doc#>>'{attendance,بلا_عذر}'
  when 'absence_dates' then p_doc->>'absence_dates'
  when 'guardian_reply' then p_doc->>'guardian_reply'
  when 'guardian_opinion' then p_doc->>'guardian_opinion'
  else null end) t(v)
where s.form_no = p_form and s.input='auto'
$function$
;
