-- public.v2_role_assign(p_section uuid, p_subject text, p_code text, p_student uuid, p_days smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 faeaf6bea2aa01b0cf23e0133e0f0c9e
CREATE OR REPLACE FUNCTION public.v2_role_assign(p_section uuid, p_subject text, p_code text, p_student uuid, p_days smallint DEFAULT NULL::smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare g jsonb; v_id uuid; nm text; d int; v_until date;
begin
  g := v2.role_gate(p_section, p_subject, p_code, p_student);
  d := coalesce(p_days, (v2.rule_n((g->>'school')::uuid,'role_default_days'))::int);
  v_until := current_date + d;
  select v2.fn_display_name(full_name) into nm from v2.students where id=p_student;

  insert into v2.class_role_holders(school_id, year_id, term_no, section_id, subject_ar,
      role_code, role_ar, student_id, from_on, until_on, by_person, is_test)
  values ((g->>'school')::uuid, nullif(g->>'year','')::uuid, (g->>'term')::smallint,
      p_section, p_subject, p_code, g->>'role_ar', p_student,
      current_date, v_until, (g->>'me')::uuid, (g->>'is_test')::boolean)
  returning id into v_id;

  return jsonb_build_object('ok',true,'holder',v_id,'role_ar',g->>'role_ar',
    'until_ar', v2.fn_to_hijri(v_until),
    'msg','صار '||coalesce(nm,'الطالب')||' «'||(g->>'role_ar')||'» في '||p_subject||
          ' — إلى '||v2.fn_to_hijri(v_until));
end $function$
;
