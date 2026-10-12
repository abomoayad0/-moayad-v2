-- v2.work_gate(p_section uuid, p_subject text, p_kind text, p_scope text, p_student uuid, p_due date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 0e2d2082b01934222c2306cbcd588569
CREATE OR REPLACE FUNCTION v2.work_gate(p_section uuid, p_subject text, p_kind text, p_scope text, p_student uuid, p_due date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare
  v_sch uuid; v_me uuid; v_grade smallint; v_sec text;
  v_due date; v_open int; v_max int;
begin
  v_me := v2.current_person();
  if v_me is null then raise exception 'لا أعرف من أنت'; end if;

  select cs.school_id, cs.grade, cs.section into v_sch, v_grade, v_sec
    from v2.class_sections cs where cs.id = p_section;
  if v_sch is null then raise exception 'فصلٌ غيرُ موجود'; end if;
  if not v2.my_school(v_sch) then raise exception 'ليست مدرستَك'; end if;

  if p_kind not in ('homework','enrichment','activity','exam') then
    raise exception 'النوع: واجب أو إثراء أو نشاط أو اختبار'; end if;
  if p_scope not in ('class','student') then
    raise exception 'المدى: الفصلُ كلُّه أو طالبٌ واحد'; end if;

  if not v2.work_teaches(v_me, p_section, p_subject) then
    raise exception 'لا تُدرّس % في هذا الفصل — ولا تُكلّف بما لا تُدرّس', p_subject;
  end if;

  if p_scope = 'student' then
    if p_student is null then raise exception 'المدى طالبٌ واحد — فمن هو؟'; end if;
    if not exists (select 1 from v2.enrolments en
                    where en.student_id = p_student and en.school_id = v_sch
                      and en.grade = v_grade and en.section = v_sec
                      and en.ended_on is null) then
      raise exception 'هذا الطالبُ ليس في هذا الفصل';
    end if;
  elsif p_student is not null then
    raise exception 'المدى الفصلُ كلُّه — فلا يُسمّى طالب';
  end if;

  if p_due is null then
    if p_kind = 'homework' and v2.rule_n(v_sch,'work_homework_needs_due') = 1 then
      raise exception 'الواجبُ يلزمه موعدُ تسليم — ومن لوحة التحكّم';
    end if;
    v_due := current_date + (v2.rule_n(v_sch,'work_due_default_days'))::int;
  else
    v_due := p_due;
  end if;
  if v_due < current_date then raise exception 'الموعدُ قد مضى'; end if;
  if v_due > current_date + (v2.rule_n(v_sch,'work_due_max_days'))::int then
    raise exception 'الموعدُ أبعدُ من % يومًا — وهو أقصى ما تسمح به لوحةُ التحكّم',
      v2.ar_num(v2.rule_n(v_sch,'work_due_max_days'));
  end if;

  v_max := (v2.rule_n(v_sch,'work_max_open_per_section'))::int;
  select count(*) into v_open from v2.class_work w
   where w.section_id = p_section and w.subject_ar = p_subject
     and w.voided_at is null and w.due_on >= current_date;
  if v_open >= v_max then
    raise exception 'في هذا الفصل % عملٌ قائمٌ في %، وهو الحدُّ — سلِّمْ ما مضى أو ارفع الحدَّ من لوحة التحكّم',
      v2.ar_num(v_open), p_subject;
  end if;

  return jsonb_build_object(
    'school', v_sch, 'me', v_me, 'due', v_due,
    'year', (select y.id from v2.academic_years y
              where y.school_id = v_sch and y.is_current limit 1),
    'term', v2.fn_term_of(v_sch, current_date),
    'is_test', coalesce((select s.test_mode from v2.schools s where s.id = v_sch), false));
end $function$
;
