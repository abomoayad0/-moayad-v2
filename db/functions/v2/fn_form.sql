-- v2.fn_form(p_form smallint, p_student uuid, p_ref uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5a5c41c0e49aa23a70fd67990a164d88
CREATE OR REPLACE FUNCTION v2.fn_form(p_form smallint, p_student uuid, p_ref uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare f record; s record; e record; sc record; r record; c record; out jsonb;
begin
  select * into f from v2.official_forms where form_no = p_form;
  if f.form_no is null then raise exception 'نموذج غير معروف: %', p_form; end if;
  perform v2.assert_my_student(p_student, 'طباعة نموذج');

  select st.*, en.grade, en.section, en.school_id into s
   from v2.students st join v2.enrolments en on en.student_id=st.id and en.status='active'
   where st.id = p_student;
  select * into sc from v2.schools where id = s.school_id;

  out := jsonb_build_object(
   'form_no', f.form_no, 'title_ar', f.title_ar,
   'owner_role', f.owner_role, 'signers', to_jsonb(f.signers),
   'source', f.source_doc||' · '||f.source_page,
   'school', sc.name_ar, 'school_stage', sc.stage,
   'today_h', v2.fn_to_hijri(current_date), 'today_g', current_date,
   'student', jsonb_build_object(
     'name', s.full_name, 'short', v2.fn_display_name(s.full_name),
     'student_no', s.student_no, 'national_id', s.national_id,
     'grade_ar', v2.grade_ar(s.grade), 'section', s.section,
     'class_ar', v2.grade_ar(s.grade)||' — '||s.section),
   'guardians', coalesce((select jsonb_agg(jsonb_build_object('name',g.full_name,'phone',g.phone,'relation',g.relation))
     from v2.guardians g where g.student_id=p_student),'[]'::jsonb),
   'fields', to_jsonb(f.fields_ar), 'columns', to_jsonb(f.columns_ar));

  -- النماذج التي تُملأ من رصد سلوكي
  if p_form in (5,6,7,8,9,10) and p_ref is not null then
    select br.*, cp.text_ar problem_ar, cp.degree_no
      into r from v2.behavior_records br
      join v2.conduct_problems cp on cp.id = br.problem_id
     where br.id = p_ref;
    if r.id is not null then
      out := out || jsonb_build_object('record', jsonb_build_object(
        'problem_ar', r.problem_ar, 'degree_no', r.degree_no,
        'occurred_on', r.occurred_on, 'occurred_h', v2.fn_to_hijri(r.occurred_on),
        'weekday_ar', (select weekday_ar from v2.calendar_days d where d.on_g = r.occurred_on limit 1),
        'place', r.place, 'note', r.note,
        'occurrence_no', r.occurrence_no, 'step_no', r.step_no,
        'deducted', (select coalesce(sum(-bl.points),0) from v2.behavior_ledger bl
                     where bl.record_id = r.id and bl.kind='deduction'),
        'actions', (select jsonb_agg(jsonb_build_object(
            'text', t.text_ar, 'owner', t.owner_role, 'status', t.status,
            'on', t.ev_on, 'on_h', case when t.ev_on is null then null else v2.fn_to_hijri(t.ev_on) end,
            'evidence', t.ev_text) order by t.ord)
          from v2.behavior_tasks t where t.record_id = r.id)));
    end if;
  end if;

  -- نموذج 5: سجلّ المشكلات كلها
  if p_form = 5 then
    out := out || jsonb_build_object('rows', coalesce((select jsonb_agg(jsonb_build_object(
      'problem', cp.text_ar, 'degree', 'الدرجة '||cp.degree_no,
      'on_h', v2.fn_to_hijri(br.occurred_on), 'on_g', br.occurred_on,
      'deducted', (select coalesce(sum(-bl.points),0) from v2.behavior_ledger bl where bl.record_id=br.id and bl.kind='deduction'),
      'actions', (select string_agg(t.text_ar,' · ' order by t.ord) from v2.behavior_tasks t where t.record_id=br.id),
      'action_on_h', (select v2.fn_to_hijri(max(t.ev_on)) from v2.behavior_tasks t where t.record_id=br.id)
      ) order by br.occurred_on)
      from v2.behavior_records br join v2.conduct_problems cp on cp.id=br.problem_id
      where br.student_id=p_student),'[]'::jsonb));
  end if;

  -- نموذج 6: فرص التعويض
  if p_form = 6 then
    out := out || jsonb_build_object('rows', coalesce((select jsonb_agg(jsonb_build_object(
      'problem', cp.text_ar, 'degree', 'الدرجة '||cp.degree_no,
      'deducted', (select coalesce(sum(-bl.points),0) from v2.behavior_ledger bl where bl.record_id=br.id and bl.kind='deduction'),
      'earned', (select coalesce(sum(bl.points),0) from v2.behavior_ledger bl where bl.record_id=br.id and bl.kind='restore')
      ) order by br.occurred_on)
      from v2.behavior_records br join v2.conduct_problems cp on cp.id=br.problem_id
      where br.student_id=p_student),'[]'::jsonb));
  end if;

  -- 15 و16 و17: المواظبة
  if p_form in (15,16,17) then
    out := out || jsonb_build_object('attendance',
      (select to_jsonb(z) from v2.fn_attendance_state(p_student,
        (select year_id from v2.enrolments where student_id=p_student and status='active' limit 1)) z),
      'days', coalesce((select jsonb_agg(jsonb_build_object(
          'on_g', a.on_date, 'on_h', v2.fn_to_hijri(a.on_date),
          'weekday_ar', (select d.weekday_ar from v2.calendar_days d where d.on_g=a.on_date limit 1),
          'excused', v2.fn_is_excused(a.student_id, a.on_date)) order by a.on_date)
        from v2.attendance a where a.student_id=p_student and a.state='absent'
          and (p_form<>15 or v2.fn_is_excused(a.student_id,a.on_date))
          and (p_form<>16 or not v2.fn_is_excused(a.student_id,a.on_date))),'[]'::jsonb));
  end if;


  out := out || jsonb_build_object(
    'stage_ar', v2.stage_ar(sc.stage),
    'today_weekday', (select d.weekday_ar from v2.calendar_days d where d.on_g=current_date limit 1),
    'counselor_ar', (select v2.fn_display_name(pe.full_name) from v2.assignments a2
       join v2.people pe on pe.id=a2.person_id
       where a2.school_id=s.school_id and a2.post_key='counselor' and a2.ended_on is null limit 1),
    'actions_text', (select string_agg(t2.text_ar,' · ' order by t2.ord)
       from v2.behavior_tasks t2 where t2.record_id = p_ref),
    'absence_dates', (select string_agg(v2.fn_to_hijri(a3.on_date)||' هـ',' · ' order by a3.on_date)
       from v2.attendance a3 where a3.student_id=p_student and a3.state='absent'));
  out := out || jsonb_build_object('fields_kv', v2.fn_form_fields(p_form, out));
  return out;
end $function$
;
