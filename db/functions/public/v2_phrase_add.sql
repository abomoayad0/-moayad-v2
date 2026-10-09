-- public.v2_phrase_add(p_form smallint, p_field text, p_text text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 63a0bcaef0d766435d1f8d7f380197c9
CREATE OR REPLACE FUNCTION public.v2_phrase_add(p_form smallint, p_field text, p_text text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; src record; nid uuid; v_txt text;
begin
  perform v2.assert_role(array['principal','deputy','deputy_students','deputy_academic',
      'deputy_school','deputy_academic_school','deputy_school_students',
      'admin_assistant','admin_assistant_students','counselor'],
      'إضافةَ عبارةٍ إلى المكتبة');
  sc := v2.acting_school();
  v_txt := btrim(coalesce(p_text,''));
  if length(v_txt) < 8 then
    raise exception 'العبارةُ أقصرُ من أن تُحفظ — فاكتبها تامّةً لتنفع غيرَك'; end if;

  select * into src from v2.form_field_source where form_no=p_form and field_key=p_field;
  if src.bank_key is null then
    raise exception '%', 'هذا الحقلُ لا مكتبةَ له'||
      case when src.by_hand then ' — فهو بيدِ المستعمل بطبيعته'
           when src.compute_kind is not null then ' — فالنظامُ يحسبه'
           else ' — ولم يُعلَن منبعُه بعد' end; end if;

  if exists (select 1 from v2.phrase_bank b
              where b.bank_key=src.bank_key and btrim(b.text_ar)=v_txt
                and (b.school_id is null or b.school_id=sc)) then
    raise exception 'هذي العبارةُ في المكتبة سلفًا'; end if;

  insert into v2.phrase_bank(school_id, bank_key, problem_id, text_ar, ord, active,
      source_ar, added_by)
  values (sc, src.bank_key, null, v_txt, 50, true,
      'من مدرستك', v2.current_person())
  returning id into nid;

  perform v2.log_action(sc,null,'phrase_add','أُضيفت عبارةٌ إلى مكتبة المدرسة',
    'phrase_bank',nid, jsonb_build_object('bank_key',src.bank_key,'form',p_form,'field',p_field));

  return jsonb_build_object('ok',true,'phrase',nid,
    'note_ar','أُضيفت إلى مكتبة مدرستك في حقل «'||coalesce(src.note_ar,p_field)||'» — '||
              'فتُعرض لمن يفتح هذا الحقلَ بعدك');
end $function$
;
