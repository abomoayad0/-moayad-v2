-- public.v2_brand_upload_path(p_school uuid, p_kind text, p_ext text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5b47226b35f4df1e36c51b103749de5a
CREATE OR REPLACE FUNCTION public.v2_brand_upload_path(p_school uuid, p_kind text, p_ext text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if p_kind not in ('logo','stamp','sign') then
    raise exception 'النوع: logo أو stamp أو sign'; end if;
  if p_kind <> 'sign' then
    perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
      'رفعَ صور الهويّة البصريّة'); end if;
  return jsonb_build_object('path',
    'brand/'||p_school||'/'||p_kind||'/'||
    to_char(now(),'YYYYMMDDHH24MISS')||'.'||
    lower(coalesce(nullif(btrim(p_ext),''),'png')));
end $function$
;
