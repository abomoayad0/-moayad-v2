-- public.v2_brand_upload_path(p_school uuid, p_kind text, p_ext text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 219690bf55dc3e9ecedeb69cc5faea2c
CREATE OR REPLACE FUNCTION public.v2_brand_upload_path(p_school uuid, p_kind text, p_ext text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare me uuid;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if p_kind not in ('logo','stamp','sign') then
    raise exception 'النوع: logo أو stamp أو sign'; end if;
  if p_kind = 'sign' then
    me := v2.current_person();
    if me is null then raise exception 'لا حسابَ فعّالٌ لك'; end if;
    return jsonb_build_object('path',
      'brand/'||p_school||'/sign/'||me||'/'||
      to_char(now(),'YYYYMMDDHH24MISS')||'-'||substr(md5(random()::text),1,6)||'.'||
      lower(coalesce(nullif(btrim(p_ext),''),'png')),
      'note','توقيعُك يرفعه حسابُك وحدَه — ولا يكتب فوقه أحد');
  end if;
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
    'رفعَ صور الهويّة البصريّة');
  return jsonb_build_object('path',
    'brand/'||p_school||'/'||p_kind||'/'||
    to_char(now(),'YYYYMMDDHH24MISS')||'-'||substr(md5(random()::text),1,6)||'.'||
    lower(coalesce(nullif(btrim(p_ext),''),'png')));
end $function$
;
