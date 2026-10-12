-- public.v2_journal_add(p_kind text, p_area text, p_title text, p_text text, p_said_by text, p_source text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 cf1d50c78e0af1ae4521eb6ea0fa1ce7
CREATE OR REPLACE FUNCTION public.v2_journal_add(p_kind text, p_area text, p_title text, p_text text, p_said_by text DEFAULT 'مفرح'::text, p_source text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_id uuid;
begin
  perform v2.assert_role(array['principal','deputy','deputy_academic','deputy_school',
    'admin_assistant','info_registrar'],'إضافةَ بندٍ في سجلّ البناء');
  if btrim(coalesce(p_title,'')) = '' or btrim(coalesce(p_text,'')) = '' then
    raise exception 'العنوانُ والنصُّ مطلوبان';
  end if;
  insert into v2.build_journal (kind, area_ar, title_ar, text_ar, said_by, source_ar, by_person)
  values (btrim(p_kind), btrim(p_area), btrim(p_title), btrim(p_text),
          coalesce(nullif(btrim(coalesce(p_said_by,'')),''),'مفرح'),
          nullif(btrim(coalesce(p_source,'')),''), v2.current_person())
  returning id into v_id;
  return jsonb_build_object('ok',true,'id',v_id,
    'summary_ar','سُجّل «'||btrim(p_title)||'» في سجلّ البناء');
end $function$
;
