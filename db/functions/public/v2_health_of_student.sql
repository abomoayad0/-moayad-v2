-- public.v2_health_of_student(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 38ac07469ac6f4c7aa0025f22c694660
CREATE OR REPLACE FUNCTION public.v2_health_of_student(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid;
begin
  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  if sc is null then raise exception 'الطالبُ لا قيدَ فعّالَ له'; end if;
  perform v2.assert_my_school(sc,'الملفَّ الصحّيَّ للطالب');
  perform v2.assert_role(array['health_counselor','principal','deputy','deputy_students',
      'deputy_school','deputy_school_students'],'الملفَّ الصحّيَّ للطالب');
  return jsonb_build_object(
    'student',(select v2.fn_display_name(full_name) from v2.students where id=p_student),
    'kinds', coalesce((select jsonb_agg(jsonb_build_object('code',k.code,'label_ar',k.label_ar,
        'note_ar',k.note_ar) order by k.ord) from v2.health_kinds k where k.active),'[]'::jsonb),
    'rows', coalesce((select jsonb_agg(jsonb_build_object(
        'case',c.id,'kind',c.kind,
        'kind_ar',(select label_ar from v2.health_kinds k where k.code=c.kind),
        'title_ar',c.title_ar,'teacher_hint_ar',c.teacher_hint_ar,'severity',c.severity,
        'private_note_ar',c.private_note_ar,
        'from_ar',v2.fn_to_hijri(c.from_on),
        'until_ar', case when c.until_on is null then null else v2.fn_to_hijri(c.until_on) end,
        'reviewed_ar', case when c.reviewed_on is null then null else v2.fn_to_hijri(c.reviewed_on) end,
        'due_review', c.reviewed_on is null
            and c.from_on < current_date - v2.rule_n(sc,'health_review_days'),
        'by_ar',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=c.by_person),
        'ended', c.ended_at is not null, 'end_reason', c.end_reason)
        order by c.ended_at nulls first, c.severity desc, c.from_on desc)
      from v2.health_cases c where c.student_id=p_student),'[]'::jsonb),
    'note_ar','اسمُ الحالةِ والخاصُّ لا يصلان المعلّم — يصله إرشادُ التعامل ودرجةُ الانتباه');
end $function$
;
