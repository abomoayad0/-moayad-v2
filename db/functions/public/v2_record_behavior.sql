-- public.v2_record_behavior(p_student uuid, p_problem integer, p_place text, p_note text, p_period smallint, p_victim uuid, p_injury boolean, p_damage boolean, p_seizure boolean, p_seizure_legal boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2f61a14b8036a807c8f8b3e9ead1df7e
CREATE OR REPLACE FUNCTION public.v2_record_behavior(p_student uuid, p_problem integer, p_place text DEFAULT NULL::text, p_note text DEFAULT NULL::text, p_period smallint DEFAULT NULL::smallint, p_victim uuid DEFAULT NULL::uuid, p_injury boolean DEFAULT false, p_damage boolean DEFAULT false, p_seizure boolean DEFAULT false, p_seizure_legal boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare rid uuid; r record; ded numeric; tm smallint; sc uuid; yid uuid;
        ptxt text; msg text; st text; d text; h text; ctx text;
begin
  perform v2.assert_role(array['counselor','deputy_students','deputy','principal',
      'admin_assistant','admin_assistant_students','subject_teacher','sped_teacher',
      'gifted_teacher'],'رصد المخالفات');
  perform v2.assert_my_student(p_student,'رصد مخالفة');
  if v2.is_absent_today(p_student) then
    raise exception 'الطالبُ غائبٌ اليوم — فلا يُرصد عليه شيء'; end if;

  select e.school_id, e.year_id into sc, yid from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;

  -- 🔑 لا يُفترض الفصلُ صامتًا
  tm := v2.fn_term_of(sc, current_date);
  if tm is null then
    if not exists (select 1 from v2.terms t where t.year_id=yid) then
      raise exception 'لا فصولَ دراسيّةٌ في تقويم مدرستك — أسّسها من لوحة التحكّم أوّلًا'; end if;
    raise exception 'اليومُ خارجَ حدود الفصول الدراسيّة المسجّلة في التقويم';
  end if;

  rid := v2.fn_record_behavior(p_student,p_problem,tm,p_period,p_place,p_note,
      p_victim,p_injury,p_damage,p_seizure,p_seizure_legal, v2.current_person());

  select br.*, cp.text_ar ptext, cp.degree_no dno, cp.source_page spg into r
    from v2.behavior_records br join v2.conduct_problems cp on cp.id=br.problem_id
   where br.id=rid;
  ptxt := rtrim(btrim(r.ptext),'.');
  select coalesce(-sum(points),0) into ded from v2.behavior_ledger
   where record_id=rid and kind='deduction';

  -- 🔑 السجلُّ الزمنيُّ يُكتب
  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,is_test)
  values (r.school_id,'behavior_record',current_date,p_student,
      'رُصدت مخالفة — '||ptxt,
      'الرصدةُ '||v2.ord_ar(r.occurrence_no)||' · '||v2.degree_ar(r.dno)||
      ' · '||v2.page_ar(r.spg)||
      case when ded>0 then ' · وحُسمت '||v2.ar_num(ded)||' من السلوك الإيجابيّ' else '' end,
      'behavior_records',rid,'all',
      coalesce((select test_mode from v2.schools where id=r.school_id),false));

  if ded > 0 then
    insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
        ref_table,ref_id,visible_to,is_test)
    values (r.school_id,'deduction',current_date,p_student,
        'حُسمت '||v2.ar_num(ded)||' من السلوك الإيجابيّ',
        'الإجراءُ '||v2.ar_num(r.step_no)||' · '||ptxt,
        'behavior_records',rid,'all',
        coalesce((select test_mode from v2.schools where id=r.school_id),false));
  end if;

  return jsonb_build_object(
    'ok',true,'record',rid,
    'problem', ptxt,
    'degree_ar', v2.degree_ar(r.dno),
    'page_ar', v2.page_ar(r.spg),
    'occurrence', r.occurrence_no,
    'occurrence_ar', v2.ord_ar(r.occurrence_no),
    'step', r.step_no,
    'deducted', ded,
    'headline',
      'رُصدت المخالفة — '||ptxt||' · الرصدةُ '||v2.ord_ar(r.occurrence_no)||
      case when ded > 0 then ' · وحُسمت '||v2.ar_num(ded)||' من السلوك الإيجابيّ'
           else ' · ولا حسمَ في هذي المرّة' end,
    'tasks', (select coalesce(jsonb_agg(jsonb_build_object(
          'id',t.id,'kind',t.kind,'text',t.text_ar,'owner',t.owner_role,
          'status',t.status,'skip_reason',t.skip_reason) order by t.ord),'[]'::jsonb)
        from v2.behavior_tasks t where t.record_id=rid),
    'score', v2.behavior_score(p_student, r.year_id, r.term_no));
exception when others then
  get stacked diagnostics st=returned_sqlstate, msg=message_text, d=pg_exception_detail,
    h=pg_exception_hint, ctx=pg_exception_context;
  perform v2.fn_log_error(msg,'v2_record_behavior','السلوك','رصد مخالفة',
    jsonb_build_object('student',p_student,'problem',p_problem,'period',p_period),
    st,d,h,ctx,'bridge', case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', msg using errcode = st;
end $function$
;
