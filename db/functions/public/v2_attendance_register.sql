-- public.v2_attendance_register(p_from date, p_to date, p_grade smallint, p_section text, p_student uuid, p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ffd621381a10790c01b68f9290c1061c
CREATE OR REPLACE FUNCTION public.v2_attendance_register(p_from date DEFAULT NULL::date, p_to date DEFAULT NULL::date, p_grade smallint DEFAULT NULL::smallint, p_section text DEFAULT NULL::text, p_student uuid DEFAULT NULL::uuid, p_school uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; yr uuid; rows jsonb; n integer;
begin
  perform v2.assert_role(array['principal','deputy','deputy_students',
      'admin_assistant','admin_assistant_students','counselor'],'سجلّ المواظبة');
  sc := coalesce(p_school, v2.acting_school());
  perform v2.assert_my_school(sc,'سجلّ المواظبة');
  if p_student is not null then perform v2.assert_my_student(p_student,'سجلّ مواظبة الطالب'); end if;
  select id into yr from v2.academic_years where school_id = sc and is_current limit 1;

  select coalesce(jsonb_agg(to_jsonb(q)),'[]'::jsonb) into rows
    from v2.fn_register_attendance(sc, yr, p_from, p_to, p_grade, p_section, p_student) q;
  n := jsonb_array_length(rows);

  return jsonb_build_object('rows', rows, 'count', n,
    'summary_ar', case when n = 0 then 'لا صفَّ في هذا المدى'
      else 'في السجلّ '||v2.ar_count(n,'طالبٌ واحد','طالبان','طلّاب','طالبًا') end,
    'note_ar','نسبةُ الغياب في هذا السجلّ محسوبةٌ على أيّام الدراسة المقرّرة في المدى المطلوب · '||
      'وحدُّ الحرمان يُقاس على السنة كلِّها (م31 بند 3) لا على المدى');
end $function$
;
