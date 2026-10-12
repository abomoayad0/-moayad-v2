-- public.v2_work_set(p_section uuid, p_subject text, p_body text, p_kind text, p_page text, p_due date, p_period smallint, p_scope text, p_student uuid, p_shows boolean, p_notify boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 dc8b49999ba191b3b4dca60067246805
CREATE OR REPLACE FUNCTION public.v2_work_set(p_section uuid, p_subject text, p_body text, p_kind text DEFAULT 'homework'::text, p_page text DEFAULT NULL::text, p_due date DEFAULT NULL::date, p_period smallint DEFAULT NULL::smallint, p_scope text DEFAULT 'class'::text, p_student uuid DEFAULT NULL::uuid, p_shows boolean DEFAULT NULL::boolean, p_notify boolean DEFAULT NULL::boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare g jsonb; v_id uuid; v_sch uuid; v_lbl text; v_shows boolean; v_notify boolean;
begin
  if coalesce(trim(p_body),'') = '' then raise exception 'اكتب نصَّ العمل'; end if;

  g := v2.work_gate(p_section, p_subject, p_kind, p_scope, p_student, p_due);
  v_sch := (g->>'school')::uuid;
  v_shows  := coalesce(p_shows,  v2.rule_n(v_sch,'work_shows_default') = 1);
  v_notify := coalesce(p_notify, v2.rule_n(v_sch,'work_notify_guardian_default') = 1);
  v_lbl := case p_kind when 'homework' then 'الواجب' when 'enrichment' then 'الإثراء'
                       when 'activity' then 'النشاط' else 'الاختبار' end;

  insert into v2.class_work (school_id, year_id, term_no, section_id, subject_ar,
      kind, scope, student_id, body_ar, page_ref, assigned_on, period_no, due_on,
      shows_to_student, notify_guardian, by_person, is_test)
  values (v_sch, (g->>'year')::uuid, (g->>'term')::smallint, p_section, p_subject,
      p_kind, p_scope, p_student, trim(p_body), nullif(trim(p_page),''),
      current_date, p_period, (g->>'due')::date,
      v_shows, v_notify, (g->>'me')::uuid, (g->>'is_test')::boolean)
  returning id into v_id;

  return jsonb_build_object('ok', true, 'id', v_id, 'kind_ar', v_lbl,
    'due_ar', v2.fn_to_hijri((g->>'due')::date),
    'msg', 'حُفظ ' || v_lbl ||
      case when p_scope = 'student' then ' — لطالبٍ واحد' else ' — للفصل كلِّه' end ||
      case when v_shows then ' · ويصل شاشةَ الطالب' else ' · ولا يظهر للطالب' end ||
      case when v_notify then ' · ويُشعَر وليُّ أمره' else '' end);
end $function$
;
