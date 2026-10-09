-- public.v2_phrase_use(p_phrase uuid, p_form smallint, p_field text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c17b2fb10040211321298f69d72c7abb
CREATE OR REPLACE FUNCTION public.v2_phrase_use(p_phrase uuid, p_form smallint DEFAULT NULL::smallint, p_field text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; b record; n int;
begin
  perform v2.assert_role(array['principal','deputy','deputy_students','deputy_academic',
      'deputy_school','deputy_academic_school','deputy_school_students',
      'admin_assistant','admin_assistant_students','counselor','subject_teacher'],
      'اختيارَ عبارة');
  sc := v2.acting_school();
  select * into b from v2.phrase_bank where id = p_phrase and active;
  if b.id is null then raise exception 'العبارةُ غيرُ موجودةٍ أو موقوفة'; end if;

  insert into v2.phrase_use(phrase_id, school_id, person_id, form_no, field_key)
  values (p_phrase, sc, v2.current_person(), p_form, p_field);

  select count(*) into n from v2.phrase_use where phrase_id=p_phrase and school_id=sc;
  return jsonb_build_object('ok',true,'text',b.text_ar,'used',n,
    'note_ar','أُدرجت وتبقى قابلةً للتعديل · واستعمالُها '||
              v2.ar_count(n,'مرّةً واحدةً','مرّتين','مرّات','مرّةً')||' في مدرستك، فترتفع في العرض');
end $function$
;
