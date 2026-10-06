-- public.v2_enrolment_end(p_school uuid, p_student uuid, p_reason text, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8309346715f1d5667fbdd1e746d7f30d
CREATE OR REPLACE FUNCTION public.v2_enrolment_end(p_school uuid, p_student uuid, p_reason text, p_note text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','info_registrar'],
                         'إنهاءَ قيد طالب');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if p_reason not in ('transferred','graduated','withdrawn','deceased',
                      'year_closed','suspended','absent_long','travel','other') then
    raise exception 'سببُ إنهاء القيد غيرُ معروف — اقرأ القائمة من v2_enrol_reasons'; end if;
  if p_reason='other' and btrim(coalesce(p_note,''))='' then
    raise exception 'اكتب السببَ حين تختار «أخرى»'; end if;

  update v2.enrolments
     set status='ended', ended_on=current_date, end_reason=p_reason
   where student_id=p_student and school_id=p_school and status='active';
  if not found then raise exception 'لا قيدَ فعّالٌ لهذا الطالب في مدرستك'; end if;

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,is_test)
  values (p_school,'other',current_date,p_student,
      'أُنهي قيدُ الطالب — '||v2.enrol_reason_ar(p_reason),
      coalesce(nullif(btrim(coalesce(p_note,'')),''),'بلا ملاحظة'),
      'enrolments',p_student,'staff',
      coalesce((select test_mode from v2.schools where id=p_school),false));

  update v2.students  set portal_active=false where id=p_student;
  update v2.guardians set portal_active=false where student_id=p_student;
  return jsonb_build_object('ok',true,'reason',v2.enrol_reason_ar(p_reason),
    'note','أُنهي القيدُ وأُغلقت البوّابتان — والسجلُّ باقٍ');
end $function$
;
