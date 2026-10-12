-- public.v2_skill_reports_board(p_school uuid, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 346152358e337617d79ca7136e7544cf
CREATE OR REPLACE FUNCTION public.v2_skill_reports_board(p_school uuid, p_term smallint DEFAULT NULL::smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare tm smallint; r jsonb; v_max int; n_exp int; n_app int; n_not int;
begin
  perform v2.assert_role(array['principal','deputy','deputy_academic','admin_assistant'],
    'قراءةَ لوحة تقارير تقويم المهارات');
  perform v2.assert_my_school(p_school,'قراءةَ لوحة تقارير تقويم المهارات');
  tm := coalesce(p_term, v2.fn_term_of(p_school, current_date));
  v_max := v2.rule_n(p_school,'assess_notices_per_term');

  select coalesce(jsonb_agg(jsonb_build_object(
      'report', x.id, 'student', x.student_id, 'name_ar', x.nm, 'class_ar', x.cls,
      'round', x.round_no, 'of', v_max,
      'mastered', x.mastered_n, 'unmastered', x.unmastered_n, 'unmeasured', x.unmeasured_n,
      'tools_ar', coalesce(x.tools_ar,'لم تُوسَم أداة'),
      'weak', x.weak,
      'expert_ar', coalesce(x.expert_ar,'—'),
      'state_ar', case
        when x.notified_at is not null then '🟢 أُشعر وليُّ الأمر'
        when x.approved_at is not null then '🟠 اعتُمد · وينتظر الإشعار'
        when x.weak and x.expert_at is null then '🔴 ذو ضعفٍ · وينتظر استشارةَ المعلّم الخبير'
        else '🟠 أُعدّ · وينتظر اعتمادَ الوكيل' end
    ) order by x.weak desc, x.nm, x.round_no), '[]'::jsonb),
    count(*) filter (where x.weak and x.expert_at is null),
    count(*) filter (where x.approved_at is null),
    count(*) filter (where x.approved_at is not null and x.notified_at is null)
    into r, n_exp, n_app, n_not
    from (select sr.*, v2.fn_display_name(s.full_name) nm,
                 coalesce(cs.label_ar,'—') cls,
                 (select v2.fn_display_name(pe.full_name) from v2.people pe where pe.id=sr.expert_person) expert_ar
            from v2.skill_reports sr
            join v2.students s on s.id = sr.student_id
            left join v2.enrolments e on e.student_id=sr.student_id and e.status='active'
            left join v2.class_sections cs on cs.school_id=e.school_id and cs.grade=e.grade and cs.section=e.section
           where sr.school_id=p_school and sr.term_no=tm and sr.voided_at is null) x;

  return jsonb_build_object('ok',true,'term',tm,'rows',r,'count',jsonb_array_length(r),
    'need_expert',n_exp,'need_approval',n_app,'need_notice',n_not,
    'summary_ar', case when jsonb_array_length(r)=0
      then 'لا تقريرَ تقويمٍ في الفصل '||v2.ar_num(tm)||' بعد'
      else v2.ar_count(jsonb_array_length(r),'تقريرٌ واحد','تقريران','تقاريرَ','تقريرًا')
           ||' · ينتظر المعلّمَ الخبيرَ '||v2.ar_num(n_exp)
           ||' · ينتظر الاعتمادَ '||v2.ar_num(n_app)
           ||' · ينتظر الإشعارَ '||v2.ar_num(n_not) end,
    'note_ar','ومالكُ الإجراء الوكيلُ للشؤون التعليميّة — '||v2.cite_of('assess.approve_reports')
      ||' · والإشعارُ مرّتان في كلّ فصلٍ — '||v2.cite_of('assess.guardian_twice'));
end $function$
;
