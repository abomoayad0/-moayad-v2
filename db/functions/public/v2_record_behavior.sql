-- public.v2_record_behavior(p_student uuid, p_problem integer, p_place text, p_note text, p_period smallint, p_victim uuid, p_injury boolean, p_damage boolean, p_seizure boolean, p_seizure_legal boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8858feaaf5476d6550172a8cbba936e9
CREATE OR REPLACE FUNCTION public.v2_record_behavior(p_student uuid, p_problem integer, p_place text DEFAULT NULL::text, p_note text DEFAULT NULL::text, p_period smallint DEFAULT NULL::smallint, p_victim uuid DEFAULT NULL::uuid, p_injury boolean DEFAULT false, p_damage boolean DEFAULT false, p_seizure boolean DEFAULT false, p_seizure_legal boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare rid uuid; r record; ded numeric; tm smallint; sc uuid;
        msg text; st text; d text; h text; ctx text;
begin
  perform v2.assert_role(array['counselor','deputy_students','deputy','principal',
      'admin_assistant','admin_assistant_students','subject_teacher','sped_teacher',
      'gifted_teacher'],'رصد المخالفات');
  perform v2.assert_my_student(p_student,'رصد مخالفة');

  -- 🔒 الغائبُ لا يُرصد عليه شيء
  if v2.is_absent_today(p_student) then
    raise exception 'الطالبُ غائبٌ اليوم — فلا يُرصد عليه شيء';
  end if;

  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  tm := coalesce(v2.fn_term_of(sc, current_date), 1);

  rid := v2.fn_record_behavior(p_student,p_problem,tm,p_period,p_place,p_note,
      p_victim,p_injury,p_damage,p_seizure,p_seizure_legal, v2.current_person());

  select br.*, cp.text_ar ptext, cp.degree_no dno into r
    from v2.behavior_records br join v2.conduct_problems cp on cp.id=br.problem_id
   where br.id=rid;
  select coalesce(-sum(points),0) into ded from v2.behavior_ledger
   where record_id=rid and kind='deduction';

  return jsonb_build_object(
    'ok',true,'record',rid,
    'problem', r.ptext,
    'degree_ar', v2.degree_ar(r.dno),
    'occurrence', r.occurrence_no,
    'occurrence_ar', v2.ord_ar(r.occurrence_no),
    'step', r.step_no,
    'deducted', ded,
    'headline',
      'رُصدت المخالفة — '||r.ptext||' · الرصدةُ '||v2.ord_ar(r.occurrence_no)||
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
