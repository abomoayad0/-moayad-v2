-- public.v2_student_work()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 71e585943d4348f4fbe20244310ca99a
CREATE OR REPLACE FUNCTION public.v2_student_work()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_st uuid;
begin
  select s.id into v_st from v2.students s
   where s.user_id = auth.uid() and coalesce(s.portal_active,false);
  if v_st is null then raise exception 'بوّابتُك غيرُ مفتوحة'; end if;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
        'kind_ar', case w.kind when 'homework' then 'واجب' when 'enrichment' then 'إثراء'
                               when 'activity' then 'نشاط' else 'اختبار' end,
        'subject', w.subject_ar, 'body', w.body_ar, 'page', w.page_ref,
        'for_me_alone', w.scope = 'student',
        'due_ar', v2.fn_to_hijri(w.due_on),
        'days_left', (w.due_on - current_date),
        'late', w.due_on < current_date,
        'by_ar', (select v2.fn_display_name(p.full_name) from v2.people p
                   where p.id = w.by_person))
      order by w.due_on)
    from v2.class_work w
    join v2.class_sections cs on cs.id = w.section_id
    join v2.enrolments en on en.student_id = v_st
         and en.school_id = w.school_id and en.ended_on is null
         and en.grade = cs.grade and en.section = cs.section
    where w.voided_at is null and w.shows_to_student
      and (w.scope = 'class' or w.student_id = v_st)
      and w.due_on >= current_date - 7), '[]'::jsonb);
end $function$
;
