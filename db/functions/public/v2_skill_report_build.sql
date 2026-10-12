-- public.v2_skill_report_build(p_student uuid, p_round smallint, p_term smallint, p_weak_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 82d42f314543efe58725746251d8964c
CREATE OR REPLACE FUNCTION public.v2_skill_report_build(p_student uuid, p_round smallint, p_term smallint DEFAULT NULL::smallint, p_weak_why text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; yr uuid; tm smallint; c jsonb; v_id uuid; v_max int; v_min int;
        n_ok int; n_no int; n_none int; v_weak boolean; v_tools text; nm text;
begin
  perform v2.assert_my_student(p_student,'إعدادَ تقرير تقويم المهارات');
  perform v2.assert_role(array['subject_teacher','sped_teacher','gifted_teacher',
    'deputy_academic','deputy','principal'],'إعدادَ تقرير تقويم المهارات');

  select e.school_id, e.year_id into sc, yr from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  if sc is null then raise exception 'الطالب لا قيد فعّال له'; end if;
  tm := coalesce(p_term, v2.fn_term_of(sc, current_date));

  v_max := v2.rule_n(sc,'assess_notices_per_term');
  if p_round is null or p_round < 1 or p_round > v_max then
    raise exception 'دورةُ التقويم من واحدةٍ إلى % — ونصُّه: %', v2.ar_num(v_max), v2.cite_of('assess.guardian_twice');
  end if;

  select public.v2_skill_card(p_student, tm) into c;
  n_ok := (c->>'mastered')::int; n_no := (c->>'unmastered')::int; n_none := (c->>'unmeasured')::int;
  if n_ok + n_no = 0 then
    raise exception 'لا مهارةَ مقيسةً لهذا الطالب في الفصل % — فلا تقريرَ بلا قياس', v2.ar_num(tm); end if;

  v_min  := v2.rule_n(sc,'weak_unmastered_min');
  v_weak := n_no >= v_min;

  select string_agg(distinct t.label_ar,' · ') into v_tools
    from v2.skill_marks m
    join v2.assess_tools t on t.key = m.tool_key
   where m.student_id=p_student and m.term_no=tm and m.voided_at is null;

  insert into v2.skill_reports(school_id,student_id,year_id,term_no,round_no,
      mastered_n,unmastered_n,unmeasured_n,tools_ar,weak,weak_why_ar,prepared_by,state,is_test)
  values (sc,p_student,yr,tm,p_round,n_ok,n_no,n_none,v_tools,v_weak,
      nullif(btrim(coalesce(p_weak_why,'')),''), v2.current_person(),
      case when v_weak then 'with_expert' else 'draft' end,
      coalesce((select test_mode from v2.schools where id=sc),false))
  on conflict (school_id,student_id,term_no,round_no) where voided_at is null
  do update set mastered_n=excluded.mastered_n, unmastered_n=excluded.unmastered_n,
      unmeasured_n=excluded.unmeasured_n, tools_ar=excluded.tools_ar,
      weak=excluded.weak, weak_why_ar=coalesce(excluded.weak_why_ar, v2.skill_reports.weak_why_ar),
      prepared_by=excluded.prepared_by, prepared_at=now(),
      state = case when v2.skill_reports.state in ('approved','notified') then v2.skill_reports.state
                   when excluded.weak then 'with_expert' else 'draft' end
  returning id into v_id;

  select v2.fn_display_name(full_name) into nm from v2.students where id=p_student;
  return jsonb_build_object('ok',true,'report',v_id,'round',p_round,'term',tm,
    'mastered',n_ok,'unmastered',n_no,'unmeasured',n_none,'weak',v_weak,
    'tools_ar',coalesce(v_tools,'لم تُوسَم أداةٌ'),
    'summary_ar','أُعدّ تقريرُ '||coalesce(nm,'الطالب')||' — الدورةُ '||v2.ar_num(p_round)
      ||' · متقنٌ '||v2.ar_num(n_ok)||' · غيرُ متقنٍ '||v2.ar_num(n_no),
    'note_ar', case when v_weak
      then '🔴 ذو ضعفٍ أكاديميّ (غيرُ المتقن '||v2.ar_num(n_no)||' والعتبةُ '||v2.ar_num(v_min)
           ||') — فيلزم استشارةُ المعلّم الخبير قبل الاعتماد · '||v2.cite_of('assess.weak_with_expert')
      else 'ولا ضعفَ أكاديميًّا — فيُعرض على الوكيل للاعتماد · '||v2.cite_of('assess.approve_reports') end);
end $function$
;
