-- public.v2_record_behavior(p_student uuid, p_problem integer, p_place text, p_note text, p_period smallint, p_victim uuid, p_injury boolean, p_damage boolean, p_seizure boolean, p_seizure_legal boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ad2bada1ada7e5ce0af13bc849bafaeb
CREATE OR REPLACE FUNCTION public.v2_record_behavior(p_student uuid, p_problem integer, p_place text DEFAULT NULL::text, p_note text DEFAULT NULL::text, p_period smallint DEFAULT NULL::smallint, p_victim uuid DEFAULT NULL::uuid, p_injury boolean DEFAULT false, p_damage boolean DEFAULT false, p_seizure boolean DEFAULT false, p_seizure_legal boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; t smallint; rid uuid; st text; m text; d text; h text; c text;
begin
  perform v2.assert_my_student(p_student,'رصد مشكلة سلوكية');
  perform v2.assert_role(array['counselor','deputy_students','admin_assistant','subject_teacher','sped_teacher','gifted_teacher'],
    'رصد المشكلات السلوكية');
  select e.school_id into sc from v2.enrolments e where e.student_id=p_student and e.status='active' limit 1;
  t := v2.fn_term_of(sc, current_date);
  rid := v2.fn_record_behavior(p_student,p_problem,t,p_period,p_place,p_note,p_victim,
    p_injury,p_damage,p_seizure,p_seizure_legal,v2.current_person());
  return jsonb_build_object('record_id', rid,
    'tasks', (select jsonb_agg(jsonb_build_object('id',x.id,'text',x.text_ar,'owner',x.owner_role,'status',x.status) order by x.ord)
              from v2.behavior_tasks x where x.record_id=rid));
exception when others then
  get stacked diagnostics st=returned_sqlstate, m=message_text, d=pg_exception_detail,
    h=pg_exception_hint, c=pg_exception_context;
  perform v2.fn_log_error(m,'v2_record_behavior','المخالفات السلوكية','رصد مخالفة',
    jsonb_build_object('student',p_student,'problem',p_problem,'place',p_place), st,d,h,c,'bridge',
    case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', m using errcode = st;
end $function$
;
