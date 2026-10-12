-- public.v2_term_split_object(p_school uuid, p_grade smallint, p_subject text, p_evidence text, p_claim_unit smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7e6894361f66b034799b3a4f5b0578c6
CREATE OR REPLACE FUNCTION public.v2_term_split_object(p_school uuid, p_grade smallint, p_subject text, p_evidence text, p_claim_unit smallint DEFAULT NULL::smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_id uuid; v_cur smallint;
begin
  perform v2.assert_my_school(p_school,'الاعتراضَ على حدّ الفصلين');
  perform v2.assert_role(array['principal','deputy','deputy_academic','deputy_school',
    'admin_assistant','info_registrar','subject_teacher'],'الاعتراضَ على حدّ الفصلين');
  if btrim(coalesce(p_evidence,'')) = '' then
    raise exception 'حجّةُ الاعتراض مطلوبةٌ — كأن تقول: كتابُ الفصل الأوّل ينتهي بالوحدة كذا';
  end if;

  select term1_until_unit into v_cur from v2.curriculum_term_split
   where grade=p_grade and subject_ar=btrim(p_subject);

  insert into v2.term_split_objections (school_id, grade, subject_ar, claim_unit,
      evidence_ar, raised_by)
  values (p_school, p_grade, btrim(p_subject), p_claim_unit, btrim(p_evidence),
          v2.current_person())
  returning id into v_id;

  return jsonb_build_object('ok',true,'objection',v_id,'current_until_unit',v_cur,
    'summary_ar','رُفع اعتراضُك على حدّ الفصلين لـ«'||btrim(p_subject)||'» الصفّ '||p_grade
      ||' — والحدُّ الحاليُّ الوحدةُ '||coalesce(v_cur::text,'غيرُ مُقرَّر'),
    'note_ar','ولا تُعدّله مدرستُك بنفسها، فالحدُّ مرجعٌ مشتركٌ لكلّ المدارس. '
      ||'ويُنظر في حجّتك، فإن صحّت أُصلح الحدُّ مرّةً فيُصلَح للجميع.');
end $function$
;
