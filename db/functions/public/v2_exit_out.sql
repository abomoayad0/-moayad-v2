-- public.v2_exit_out(p_student uuid, p_to_where text, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4ea143283f03fdb69c86b2b289b750ed
CREATE OR REPLACE FUNCTION public.v2_exit_out(p_student uuid, p_to_where text, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare g jsonb; v_id uuid; nm text; v_ar text; v_cls uuid; v_sc uuid; v_per smallint;
begin
  g := v2.exit_gate(p_student, p_to_where, p_note);
  v_ar := v2.exit_where_ar(p_to_where);
  v_sc := (g->>'school')::uuid; v_per := (g->>'period')::smallint;
  select v2.fn_display_name(full_name) into nm from v2.students where id=p_student;

  if v_per is not null then
    v_cls := v2.session_of(v_sc, (g->>'me')::uuid, current_date, v_per, null,
                           v2.rule_n(v_sc,'session_auto_open') = 1);
  end if;

  insert into v2.class_exits (school_id, year_id, term_no, student_id, section_id,
      on_date, period_no, slot_id, class_session, to_where, to_where_ar, note_ar,
      out_by, out_role_ar, is_test)
  values (v_sc, nullif(g->>'year','')::uuid, (g->>'term')::smallint,
      p_student, nullif(g->>'section','')::uuid, current_date,
      v_per, nullif(g->>'slot','')::uuid, v_cls,
      p_to_where, v_ar, nullif(btrim(coalesce(p_note,'')),''),
      (g->>'me')::uuid, v2.role_ar(v2.my_role()), (g->>'is_test')::boolean)
  returning id into v_id;

  return jsonb_build_object('ok',true,'exit',v_id,'to_ar',v_ar,'class_session',v_cls,
    'msg','خرج '||coalesce(nm,'الطالب')||' إلى '||v_ar||' — وعودتُه تُسجَّل',
    'warn_minutes', v2.rule_n(v_sc,'card_exit_minutes_warn'));
end $function$
;
