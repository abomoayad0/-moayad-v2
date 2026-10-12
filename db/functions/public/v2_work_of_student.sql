-- public.v2_work_of_student(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ff317026a79a74a61def45e4ec0583ee
CREATE OR REPLACE FUNCTION public.v2_work_of_student(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; v_days int;
begin
  perform v2.assert_my_student(p_student, 'أعمالُ الطالب');
  select e.school_id into sc from v2.enrolments e
   where e.student_id = p_student and e.status='active' limit 1;
  v_days := (v2.rule_n(sc,'work_window_days'))::int;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
        'id', w.id, 'kind', w.kind,
        'kind_ar', coalesce((select k.label_ar from v2.work_kinds k where k.code = w.kind), w.kind),
        'subject', w.subject_ar, 'body', w.body_ar, 'page', w.page_ref,
        'for_him_alone', w.scope = 'student',
        'due_on', w.due_on, 'due_ar', v2.fn_to_hijri(w.due_on),
        'late', w.due_on < current_date,
        'shows', w.shows_to_student,
        'by_ar', (select v2.fn_display_name(p.full_name) from v2.people p
                   where p.id = w.by_person),
        'mine', w.by_person = v2.current_person())
      order by w.due_on desc)
    from v2.class_work w
    join v2.class_sections cs on cs.id = w.section_id
    join v2.enrolments en on en.student_id = p_student
         and en.school_id = w.school_id and en.ended_on is null
         and en.grade = cs.grade and en.section = cs.section
    where w.voided_at is null
      and (w.scope = 'class' or w.student_id = p_student)
      and w.assigned_on >= current_date - v_days), '[]'::jsonb);
end $function$
;
