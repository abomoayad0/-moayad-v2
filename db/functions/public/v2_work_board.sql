-- public.v2_work_board(p_section uuid, p_subject text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7b7ca38e5e69e15177edfe8966c2e438
CREATE OR REPLACE FUNCTION public.v2_work_board(p_section uuid, p_subject text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_sch uuid; v_days int;
begin
  select school_id into v_sch from v2.class_sections where id = p_section;
  if v_sch is null then raise exception 'فصلٌ غيرُ موجود'; end if;
  if not v2.my_school(v_sch) then raise exception 'ليست مدرستَك'; end if;
  v_days := (v2.rule_n(v_sch,'work_board_days'))::int;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
        'id', w.id, 'kind', w.kind,
        'kind_ar', coalesce((select k.label_ar from v2.work_kinds k where k.code = w.kind), w.kind),
        'subject', w.subject_ar, 'body', w.body_ar, 'page', w.page_ref,
        'scope_ar', case when w.scope = 'class' then 'الفصلُ كلُّه' else 'طالبٌ واحد' end,
        'student', w.student_id,
        'student_ar', (select v2.fn_display_name(s.full_name) from v2.students s
                        where s.id = w.student_id),
        'assigned_on', w.assigned_on, 'due_on', w.due_on,
        'due_ar', v2.fn_to_hijri(w.due_on),
        'late', w.due_on < current_date,
        'period_no', w.period_no,
        'shows', w.shows_to_student, 'notify', w.notify_guardian,
        'by_ar', (select v2.fn_display_name(p.full_name) from v2.people p
                   where p.id = w.by_person),
        'mine', w.by_person = v2.current_person(),
        'voided', w.voided_at is not null, 'void_reason', w.void_reason,
        'unseen', case when not w.shows_to_student then 0 else (
            select count(*) from v2.enrolments en
             join v2.students st on st.id = en.student_id
             join v2.class_sections cs2 on cs2.id = w.section_id
             where en.school_id = w.school_id and en.ended_on is null
               and en.grade = cs2.grade and en.section = cs2.section
               and (w.scope = 'class' or en.student_id = w.student_id)
               and (st.user_id is null or not coalesce(st.portal_active,false))) end)
      order by w.due_on desc, w.created_at desc)
    from v2.class_work w
    where w.section_id = p_section
      and (p_subject is null or w.subject_ar = p_subject)
      and w.assigned_on >= current_date - v_days), '[]'::jsonb);
end $function$
;
