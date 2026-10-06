-- v2.fn_form_core(p_form smallint, p_student uuid, p_ref uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9278e60ee641b4e07aa03b41909ba815
CREATE OR REPLACE FUNCTION v2.fn_form_core(p_form smallint, p_student uuid, p_ref uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare f record; s record; sc record; r record; out jsonb;
begin
  select * into f from v2.official_forms where form_no=p_form;
  select st.*, en.grade, en.section, en.school_id into s
   from v2.students st join v2.enrolments en on en.student_id=st.id and en.status='active'
   where st.id=p_student;
  if s.id is null then return '{}'::jsonb; end if;
  select * into sc from v2.schools where id=s.school_id;
  out := jsonb_build_object('form_no',f.form_no,'title_ar',f.title_ar,
    'school', sc.name_ar, 'stage_ar', v2.stage_ar(sc.stage),
    'today_h', v2.fn_to_hijri(current_date),
    'today_weekday', (select d.weekday_ar from v2.calendar_days d where d.on_g=current_date limit 1),
    'student', jsonb_build_object('name',s.full_name,'short',v2.fn_display_name(s.full_name),
      'student_no',s.student_no,'grade_ar',v2.grade_ar(s.grade),'section',s.section,
      'class_ar', v2.grade_ar(s.grade)||' — '||s.section,
      'birth_g', s.birth_date, 'birth_h', case when s.birth_date is null then null else v2.fn_to_hijri(s.birth_date)||' هـ' end),
    'guardians', coalesce((select jsonb_agg(jsonb_build_object('name',g.full_name,'phone',g.phone))
      from v2.guardians g where g.student_id=p_student),'[]'::jsonb),
    'counselor_ar', (select v2.fn_display_name(pe.full_name) from v2.assignments a2
       join v2.people pe on pe.id=a2.person_id
       where a2.school_id=s.school_id and a2.post_key='counselor' and a2.ended_on is null limit 1));
  if p_ref is not null then
    select br.*, cp.text_ar problem_ar, cp.degree_no into r
     from v2.behavior_records br join v2.conduct_problems cp on cp.id=br.problem_id where br.id=p_ref;
    if r.id is not null then
      out := out || jsonb_build_object('record', jsonb_build_object(
        'problem_ar', r.problem_ar, 'degree_no', r.degree_no,
        'occurred_h', v2.fn_to_hijri(r.occurred_on),
        'weekday_ar', (select weekday_ar from v2.calendar_days d where d.on_g=r.occurred_on limit 1)),
        'actions_text', (select string_agg(t.text_ar,' · ' order by t.ord)
          from v2.behavior_tasks t where t.record_id=p_ref));
    end if;
  end if;
  return out;
end $function$
;
