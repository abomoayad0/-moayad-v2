-- public.v2_journal_add(p_kind text, p_area text, p_title text, p_text text, p_said_by text, p_source text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9ff8abf406fbd0d58963fb7ed8a6d2d4
CREATE OR REPLACE FUNCTION public.v2_journal_add(p_kind text, p_area text, p_title text, p_text text, p_said_by text DEFAULT 'مفرح'::text, p_source text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_id uuid; v_kind text;
begin
  perform v2.assert_role(array['principal','deputy','deputy_academic','deputy_school',
    'admin_assistant','info_registrar'],'إضافةَ بندٍ في سجلّ البناء');
  if btrim(coalesce(p_title,'')) = '' or btrim(coalesce(p_text,'')) = '' then
    raise exception 'العنوانُ والنصُّ مطلوبان';
  end if;
  v_kind := btrim(coalesce(p_kind,''));
  if v_kind not in ('rule','decision','deferred','gap','mistake') then
    raise exception 'نوعُ القيد غيرُ معروف «%» — والمقبولُ: قاعدةٌ (rule) · قرارٌ (decision) · مؤجَّلٌ (deferred) · ثغرةٌ (gap) · خطأٌ (mistake)', v_kind;
  end if;

  insert into v2.build_journal (kind, area_ar, title_ar, text_ar, said_by, source_ar, by_person)
  values (v_kind, btrim(p_area), btrim(p_title), btrim(p_text),
          coalesce(nullif(btrim(coalesce(p_said_by,'')),''),'مفرح'),
          nullif(btrim(coalesce(p_source,'')),''), v2.current_person())
  returning id into v_id;
  return jsonb_build_object('ok',true,'id',v_id,
    'summary_ar','سُجّل «'||btrim(p_title)||'» في سجلّ البناء');
exception
  when not_null_violation or unique_violation or check_violation
    or foreign_key_violation or invalid_datetime_format
    or datetime_field_overflow or invalid_text_representation then
    raise exception '%', v2.say_lock('v2_journal_add', sqlstate, sqlerrm);
end $function$
;
