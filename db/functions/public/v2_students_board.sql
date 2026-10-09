-- public.v2_students_board(p_school uuid, p_grade smallint, p_section text, p_q text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a20d75138421f2cb11f7ed8585288d3e
CREATE OR REPLACE FUNCTION public.v2_students_board(p_school uuid, p_grade smallint DEFAULT NULL::smallint, p_section text DEFAULT NULL::text, p_q text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb; v_q text;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic',
      'admin_assistant','admin_assistant_students','info_registrar','counselor'],'كشف الطلّاب');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  v_q := nullif(btrim(coalesce(p_q,'')),'');
  select coalesce(jsonb_agg(jsonb_build_object(
      'student',s.id,'student_no',s.student_no,'name',s.full_name,
      'display',v2.fn_display_name(s.full_name),
      'national_id',s.national_id,'nationality',s.nationality,
      'birth_hijri',s.birth_date_hijri,'sex',s.sex,'phone',s.student_phone,
      'status',s.status,'reg_status',s.reg_status,
      'enrolment',e.id,'grade',e.grade,'section',e.section,'stage',e.stage,
      'joined_on',e.joined_on,'enr_status',e.status,
      'guardians',(select count(*) from v2.guardians g where g.student_id=s.id),
      'portal',s.portal_active)
      order by e.grade, e.section, s.full_name),'[]'::jsonb)
  into r from v2.students s
  join v2.enrolments e on e.student_id=s.id and e.school_id=p_school and e.status='active'
  where (p_grade is null or e.grade=p_grade)
    and (p_section is null or e.section=p_section)
    and (v_q is null or s.full_name ilike '%'||v_q||'%'
         or coalesce(s.student_no,'') like '%'||v_q||'%'
         or coalesce(s.national_id,'') like '%'||v_q||'%');
  return r;
end $function$
;
