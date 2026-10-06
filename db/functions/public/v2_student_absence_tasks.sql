-- public.v2_student_absence_tasks(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5fb3e6daead11aec78ecc1be83601c06
CREATE OR REPLACE FUNCTION public.v2_student_absence_tasks(p_student uuid)
 RETURNS TABLE(task_id uuid, ord smallint, text_ar text, owner_role text, owner_person uuid, owner_ar text, delegate_note text, status text, days_n smallint, excused boolean, triggered_on date, triggered_h text, evidence_kind text, evidence_ar text, hint_ar text, needs_date boolean, needs_text boolean, needs_file boolean, needs_ref boolean, needs_people boolean, needs_signature boolean, lbl_date text, lbl_text text, lbl_file text, lbl_ref text, lbl_people text, lbl_sign text, form_no smallint, form_title text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_student(p_student,'قراءة مهامّ الغياب');
  return query
   select t.id, t.ord, t.text_ar, t.owner_role,
     t.owner_person, (select v2.fn_display_name(pe.full_name) from v2.people pe where pe.id=t.owner_person),
     t.delegate_note, t.status,
     c.days_count, c.excused, c.triggered_on, v2.fn_to_hijri(c.triggered_on)||' هـ',
     k.key, k.label_ar, k.hint_ar,
     k.needs_date, k.needs_text, k.needs_file, k.needs_ref, k.needs_people, k.needs_signature,
     k.lbl_date, k.lbl_text, k.lbl_file, k.lbl_ref, k.lbl_people, k.lbl_sign,
     k.needs_form, (select f.title_ar from v2.official_forms f where f.form_no=k.needs_form)
   from v2.absence_tasks t
   join v2.absence_cases c on c.id=t.case_id
   left join v2.evidence_kinds k on k.key = coalesce(t.evidence_kind,'note')
   where c.student_id=p_student order by c.triggered_on desc, t.ord;
end $function$
;
