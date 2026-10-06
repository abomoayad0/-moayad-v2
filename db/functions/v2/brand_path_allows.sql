-- v2.brand_path_allows(p_path text, p_write boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 dcc5a286f47f5e8eee513b95b2203541
CREATE OR REPLACE FUNCTION v2.brand_path_allows(p_path text, p_write boolean)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sid uuid; kind text; owner uuid; me uuid;
begin
  if p_path is null or p_path not like 'brand/%' then return false; end if;
  begin sid := split_part(p_path,'/',2)::uuid; exception when others then return false; end;
  if not exists (select 1 from v2.schools where id=sid) then return false; end if;
  if not v2.my_school(sid) then return false; end if;

  kind := split_part(p_path,'/',3);
  if kind not in ('logo','stamp','sign') then return false; end if;

  if kind = 'sign' then
    -- 🔑 المسارُ يحمل صاحبَه: brand/<المدرسة>/sign/<الشخص>/<الملفّ>
    begin owner := split_part(p_path,'/',4)::uuid; exception when others then return false; end;
    if owner is null then return false; end if;
    me := v2.current_person();
    if p_write then
      -- توقيعُ المرء يرفعه هو وحدَه — ولا المديرُ يكتب فوقه
      return owner = me;
    end if;
    -- والقراءةُ لمنسوبي المدرسة
    return true;
  end if;

  if p_write then
    return v2.my_role() in ('principal','deputy_students','deputy','deputy_academic');
  end if;
  return true;
end $function$
;
