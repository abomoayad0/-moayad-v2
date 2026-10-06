-- public.v2_student_tasks(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 379a0fdedeee3d9fea6d725de6b4e541
CREATE OR REPLACE FUNCTION public.v2_student_tasks(p_student uuid)
 RETURNS TABLE(task_id uuid, record_id uuid, ord smallint, text_ar text, owner_role text, owner_person uuid, owner_ar text, delegate_note text, status text, problem_ar text, degree_no smallint, occurred_on date, occurred_h text, evidence_kind text, evidence_ar text, hint_ar text, needs_date boolean, needs_text boolean, needs_file boolean, needs_ref boolean, needs_people boolean, needs_signature boolean, lbl_date text, lbl_text text, lbl_file text, lbl_ref text, lbl_people text, lbl_sign text, form_no smallint, form_title text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_student(p_student,'قراءة مهامّ الطالب');
  return query
   select t.id, r.id, t.ord, t.text_ar, t.owner_role,
     t.owner_person, (select v2.fn_display_name(pe.full_name) from v2.people pe where pe.id=t.owner_person),
     t.delegate_note, t.status,
     p.text_ar, p.degree_no, r.occurred_on, v2.fn_to_hijri(r.occurred_on)||' هـ',
     k.key, k.label_ar, k.hint_ar,
     k.needs_date, k.needs_text, k.needs_file, k.needs_ref, k.needs_people, k.needs_signature,
     k.lbl_date, k.lbl_text, k.lbl_file, k.lbl_ref, k.lbl_people, k.lbl_sign,
     k.needs_form, (select f.title_ar from v2.official_forms f where f.form_no=k.needs_form)
   from v2.behavior_tasks t
   join v2.behavior_records r on r.id=t.record_id
   join v2.conduct_problems p on p.id=r.problem_id
   left join v2.evidence_kinds k on k.key = coalesce(t.evidence_kind,'note')
   where r.student_id=p_student order by r.occurred_on desc, t.ord;
end $function$
;
