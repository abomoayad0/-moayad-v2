-- public.v2_record_behavior(p_student uuid, p_problem integer, p_place text, p_note text, p_period smallint, p_victim uuid, p_injury boolean, p_damage boolean, p_seizure boolean, p_seizure_legal boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 902cae6b5066a28f1d39afcc19288122
CREATE OR REPLACE FUNCTION public.v2_record_behavior(p_student uuid, p_problem integer, p_place text DEFAULT NULL::text, p_note text DEFAULT NULL::text, p_period smallint DEFAULT NULL::smallint, p_victim uuid DEFAULT NULL::uuid, p_injury boolean DEFAULT false, p_damage boolean DEFAULT false, p_seizure boolean DEFAULT false, p_seizure_legal boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare rid uuid; r record; ded numeric; tm smallint; sc uuid; yid uuid; auto jsonb;
        ptxt text; msg text; st text; d text; h text; ctx text; v_adv text; v_ded_ar text;
        v_waive text;
begin
  perform v2.assert_role(array['counselor','deputy_students','deputy','principal',
      'admin_assistant','admin_assistant_students','subject_teacher','sped_teacher',
      'gifted_teacher'],'رصد المخالفات');
  perform v2.assert_my_student(p_student,'رصد مخالفة');
  if v2.is_absent_today(p_student) then
    raise exception 'الطالبُ غائبٌ اليوم — فلا يُرصد عليه شيء'; end if;

  select e.school_id, e.year_id into sc, yid from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;

  tm := v2.term_of_strict(sc, current_date);
  if tm is null then
    raise exception 'اليومُ غيرُ معروفٍ في تقويم مدرستك — فلا يُعرف فصلُه الدراسيّ. '
      'أسّس التقويمَ من لوحة التحكّم، أو راجع مسارَ التقويم للمدرسة';
  end if;

  rid := v2.fn_record_behavior(p_student,p_problem,tm,p_period,p_place,p_note,
      p_victim,p_injury,p_damage,p_seizure,p_seizure_legal, v2.current_person());

  select br.*, cp.text_ar ptext, cp.degree_no dno, cp.source_page spg,
         cp.advice_waived_ar waive into r
    from v2.behavior_records br join v2.conduct_problems cp on cp.id=br.problem_id
   where br.id=rid;
  ptxt := rtrim(btrim(r.ptext),'.');
  v_waive := r.waive;
  select coalesce(-sum(points),0) into ded from v2.behavior_ledger
   where record_id=rid and kind='deduction';

  v_ded_ar := v2.ar_count(ded,'درجةٌ واحدة','درجتان','درجات','درجة');

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,is_test)
  values (r.school_id,'behavior_record',current_date,p_student,
      'رُصدت مخالفة — '||ptxt,
      'الواقعةُ '||v2.ord_ar(r.occurrence_no)||' · '||v2.degree_ar(r.dno)||
      ' · '||v2.page_ar(r.spg)||
      case when ded>0 then ' · وحُسمت '||v_ded_ar||' من السلوك الإيجابيّ' else '' end,
      'behavior_records',rid,'all',
      coalesce((select test_mode from v2.schools where id=r.school_id),false));

  if ded > 0 then
    insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
        ref_table,ref_id,visible_to,is_test)
    values (r.school_id,'deduction',current_date,p_student,
        'حُسمت '||v_ded_ar||' من السلوك الإيجابيّ',
        'الإجراءُ '||v2.ar_num(r.step_no)||' · '||ptxt,
        'behavior_records',rid,'all',
        coalesce((select test_mode from v2.schools where id=r.school_id),false));
  end if;

  auto := v2.ladder_auto(rid);

  -- 🔑 النصيحةُ الغائبةُ تُقال ولا يُسكَت عنها · ويُفرَّق بين النقصِ والقرار
  select advice_ar into v_adv from v2.behavior_records where id=rid;
  if v_adv is null then
    if v_waive is not null then
      auto := jsonb_build_array(jsonb_build_object(
                'kind','advice_waived',
                'text','لا نصيحةَ لهذي المخالفة بقرار — والسببُ: '||v_waive)) || auto;
    else
      auto := jsonb_build_array(jsonb_build_object(
                'kind','advice_missing',
                'text','لا نصيحةَ مسجّلةٌ لهذي المخالفة في الواقعة '||
                       v2.ord_ar(r.occurrence_no)||
                       ' — فالطالبُ رُصد ولم يُنصَح · وتُضاف النصائحُ من لوحة التحكّم')) || auto;
    end if;
  end if;

  perform v2.log_action(sc,p_student,'record_behavior','رُصدت مخالفة',
    'behavior_records',rid, jsonb_build_object('problem',ptxt));
  return jsonb_build_object(
    'ok',true,'record',rid,'problem',ptxt,'auto',auto,
    'advice', v_adv,
    'advice_missing', (v_adv is null and v_waive is null),
    'advice_waived_ar', case when v_adv is null then v_waive else null end,
    'degree_ar', v2.degree_ar(r.dno),
    'page_ar', v2.page_ar(r.spg),
    'term', tm,
    'occurrence', r.occurrence_no,
    'occurrence_ar', v2.ord_ar(r.occurrence_no),
    'step', r.step_no, 'deducted', ded,
    'deducted_ar', case when ded > 0 then v_ded_ar else null end,
    'headline',
      'رُصدت المخالفة — '||ptxt||' · الواقعةُ '||v2.ord_ar(r.occurrence_no)||
      case when ded > 0 then ' · وحُسمت '||v_ded_ar||' من السلوك الإيجابيّ'
           else ' · ولا حسمَ في هذي المرّة' end,
    'tasks', (select coalesce(jsonb_agg(jsonb_build_object(
          'id',t.id,'kind',t.kind,'text',t.text_ar,'owner',t.owner_role,
          'status',t.status,'skip_reason',t.skip_reason,'auto_note',t.auto_note) order by t.ord),'[]'::jsonb)
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
