-- public.v2_enrolment_end(p_school uuid, p_student uuid, p_reason text, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 181062802348500384a7a07f5884a5d1
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
  if p_reason not in ('نقل','تخرّج','طيّ قيد','انقطاع','سفر','أخرى') then
    raise exception 'سببُ إنهاء القيد: نقلٌ · تخرّجٌ · طيُّ قيدٍ · انقطاعٌ · سفرٌ · أخرى'; end if;
  if p_reason='أخرى' and btrim(coalesce(p_note,''))='' then
    raise exception 'اكتب السببَ حين تختار «أخرى»'; end if;

  update v2.enrolments
     set status='ended', ended_on=current_date,
         end_reason=p_reason||case when btrim(coalesce(p_note,''))='' then ''
                                   else ' — '||btrim(p_note) end
   where student_id=p_student and school_id=p_school and status='active';
  if not found then raise exception 'لا قيدَ فعّالٌ لهذا الطالب في مدرستك'; end if;

  -- 🔒 وتُغلق بوّابتُه وبوّابةُ وليِّه
  update v2.students set portal_active=false where id=p_student;
  update v2.guardians set portal_active=false where student_id=p_student;
  return jsonb_build_object('ok',true,'note','أُنهي القيدُ وأُغلقت البوّابة — والسجلُّ باقٍ');
end $function$
;
