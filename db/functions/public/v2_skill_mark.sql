-- public.v2_skill_mark(p_student uuid, p_skill uuid, p_level text, p_note text, p_date date, p_period smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ec83b1697208b85852318c997871b01d
CREATE OR REPLACE FUNCTION public.v2_skill_mark(p_student uuid, p_skill uuid, p_level text, p_note text DEFAULT NULL::text, p_date date DEFAULT CURRENT_DATE, p_period smallint DEFAULT NULL::smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare me uuid := v2.current_person(); sc uuid; yr uuid; tm smallint;
        sk record; v_sec uuid; v_sess uuid; v_id uuid; v_role text; nm text; v_admin boolean; v_level text;
begin
  perform v2.assert_my_student(p_student,'رصدَ مستوى مهارة');
  perform v2.assert_role(array['subject_teacher','sped_teacher','gifted_teacher',
    'deputy_academic','deputy','principal','admin_assistant'],'رصدَ مستوى مهارة');
  -- المستوى يُحسم من v2.skill_levels وهو الحاكم

  select e.school_id, e.year_id into sc, yr from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  if sc is null then raise exception 'الطالب لا قيد فعّال له'; end if;
  tm := v2.fn_term_of(sc, p_date);
  v_role := coalesce(v2.role_ar(v2.my_role()),'معلم');
  v_admin := v2.my_role() in ('deputy_academic','deputy','principal','admin_assistant');
  v_level := v2.skill_level_of(sc, p_level);

  select * into sk from v2.skills where id=p_skill and voided_at is null and active;
  if sk.id is null then raise exception 'لا مهارةَ بهذا المعرّف في قائمة مدرستك'; end if;
  if sk.school_id <> sc then raise exception 'المهارةُ من قائمةِ مدرسةٍ أخرى'; end if;

  select cs.id into v_sec from v2.class_sections cs
    join v2.enrolments e2 on e2.school_id=cs.school_id and e2.grade=cs.grade and e2.section=cs.section
   where e2.student_id=p_student and e2.status='active' limit 1;
  if sk.grade is not null and sk.grade <> (select grade from v2.class_sections where id=v_sec) then
    raise exception 'المهارةُ لصفٍّ آخر — فهي للصفّ %', v2.ar_num(sk.grade); end if;

  -- المعلّمُ يرصد من داخل الاستقطاع · والوكيلُ والمديرُ لا يلزمهما
  if not v_admin then
    select rs.id into v_sess from v2.reading_sessions rs
     where rs.school_id=sc and rs.person_id=me and rs.on_date=p_date
       and rs.done and rs.voided_at is null
       and (p_period is null or rs.period_no = p_period)
     order by rs.period_no limit 1;
    if v_sess is null then
      raise exception 'لم تفتح استقطاعَ القراءة والكتابة في هذا اليوم — والرصدُ موضعُه تلك الدقائق (س-٨-ا-٣ سياسة ٠٤ ص٢٠٩)';
    end if;
  else
    select rs.id into v_sess from v2.reading_sessions rs
     where rs.school_id=sc and rs.on_date=p_date and rs.section_id=v_sec
       and rs.done and rs.voided_at is null limit 1;
  end if;

  insert into v2.skill_marks(school_id,year_id,term_no,student_id,skill_id,level,
      on_date,period_no,session_id,note_ar,recorded_by,recorded_role,is_test)
  values (sc,yr,tm,p_student,p_skill,v_level,p_date,p_period,v_sess,
      nullif(btrim(coalesce(p_note,'')),''), me, v_role,
      coalesce((select test_mode from v2.schools where id=sc),false))
  on conflict (student_id,skill_id,on_date) where voided_at is null
  do update set level=excluded.level, note_ar=excluded.note_ar,
      period_no=excluded.period_no, session_id=excluded.session_id,
      recorded_by=excluded.recorded_by, recorded_role=excluded.recorded_role, recorded_at=now()
  returning id into v_id;

  select v2.fn_display_name(full_name) into nm from v2.students where id=p_student;
  return jsonb_build_object('ok',true,'mark',v_id,'session',v_sess,
    'summary_ar','رُصد «'||sk.title_ar||'» لـ'||coalesce(nm,'الطالب')||': '||v_level,
    'note_ar','والموضعُ سجلُّ متابعة مهارات الطلّاب — '||v2.cite_of('skills.record_in_log'));
end $function$
;
