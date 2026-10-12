-- public.v2_plan_card(p_school uuid, p_grade smallint, p_subject text, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e8b7a0bf1c2cfad8c9f1a505a858d3d8
CREATE OR REPLACE FUNCTION public.v2_plan_card(p_school uuid, p_grade smallint, p_subject text, p_term smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_admin boolean := true; v_me uuid := v2.current_person(); v_n int; v_one uuid;
begin
  perform v2.assert_my_school(p_school,'قراءةَ توزيع المنهج');
  begin
    perform v2.assert_role(array['principal','deputy','deputy_academic','deputy_school',
      'admin_assistant','info_registrar'],'قراءةَ توزيع المنهج');
  exception when others then v_admin := false; end;

  if not v_admin then
    return public.v2_plan_card(p_school, p_grade, p_subject, p_term, v_me);
  end if;

  select count(*), (array_agg(owner_person))[1] into v_n, v_one from v2.lesson_plans
   where school_id=p_school and term_no=p_term and grade=p_grade and subject_ar=btrim(p_subject);
  if v_n = 1 then
    return public.v2_plan_card(p_school, p_grade, p_subject, p_term, v_one);
  end if;
  if v_n = 0 then
    return jsonb_build_object('plan',null,'summary_ar',
      'لا توزيعَ لهذي المادّة في هذا الفصل بعد — ويُحسب لكلّ معلّمٍ بزرٍّ واحد','fix','v2_plan_build');
  end if;
  return jsonb_build_object('plan',null,
    'owners',(select jsonb_agg(jsonb_build_object('owner',p.owner_person,
        'owner_ar',(select v2.fn_display_name(pe.full_name) from v2.people pe where pe.id=p.owner_person),
        'status',p.status,
        'sections',(select count(*) from v2.plan_sections(p.id))))
      from v2.lesson_plans p
     where p.school_id=p_school and p.term_no=p_term and p.grade=p_grade
       and p.subject_ar=btrim(p_subject)),
    'summary_ar','لهذي المادّة في هذا الصفّ '||v2.ar_count(v_n,'توزيعٌ واحد','توزيعان','توزيعاتٍ','توزيعًا')
      ||' — فاختر المعلّمَ، فالتوزيعُ للمعلّم في مادّته وصفّه');
end $function$
;
