-- public.v2_audit_waive(p_finding uuid, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 0d3fbe202d9198a1c067d773d6b6fe60
CREATE OR REPLACE FUNCTION public.v2_audit_waive(p_finding uuid, p_why text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare f record;
begin
  perform v2.assert_role(array['principal','deputy','deputy_academic'],'إسقاطَ خللٍ من الجرد');
  if btrim(coalesce(p_why,'')) = '' then
    raise exception 'الإسقاطُ يَلزمه سببٌ مكتوبٌ يبقى — فلا يُسكت عن خللٍ بلا بيان';
  end if;
  select * into f from v2.audit_findings where id = p_finding;
  if f.id is null then raise exception 'لا سطرَ بهذا الرقم'; end if;
  update v2.audit_findings
     set waived_at = now(), waived_by = v2.current_person(), waive_why = btrim(p_why)
   where id = p_finding;
  return 'أُسقط «'||f.object_ar||'» بسببه المكتوب — ويبقى في السجلّ ولا يُحذف';
end $function$
;
