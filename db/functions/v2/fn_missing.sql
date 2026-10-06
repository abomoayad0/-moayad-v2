-- v2.fn_missing(k v2.evidence_kinds, p_ev jsonb)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 af9f69ec33800d0a2b3347195af05850
CREATE OR REPLACE FUNCTION v2.fn_missing(k v2.evidence_kinds, p_ev jsonb)
 RETURNS text[]
 LANGUAGE sql
 IMMUTABLE
AS $function$
select array_remove(array[
  case when k.needs_date and (p_ev->>'on') is null then k.lbl_date end,
  case when k.needs_text and btrim(coalesce(p_ev->>'text',''))='' then k.lbl_text end,
  case when k.needs_file and btrim(coalesce(p_ev->>'file',''))=''
        and not coalesce((p_ev->>'refused')::boolean,false) then k.lbl_file end,
  case when k.needs_ref and btrim(coalesce(p_ev->>'ref',''))='' then k.lbl_ref end,
  case when k.needs_people and btrim(coalesce(p_ev->>'people',''))='' then k.lbl_people end,
  case when k.needs_signature and (p_ev->>'signed') is null
        and btrim(coalesce(p_ev->>'refused_reason',''))='' then k.lbl_sign||' أو سبب الامتناع' end
], null)
$function$
;
