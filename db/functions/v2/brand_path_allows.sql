-- v2.brand_path_allows(p_path text, p_write boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 74666f5180653bda33c62f6396e14114
CREATE OR REPLACE FUNCTION v2.brand_path_allows(p_path text, p_write boolean)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sid uuid;
begin
  if p_path is null or p_path not like 'brand/%' then return false; end if;
  -- المسار: brand/<المدرسة>/logo|stamp|sign/...
  begin sid := split_part(p_path,'/',2)::uuid; exception when others then return false; end;
  if not exists (select 1 from v2.schools where id=sid) then return false; end if;
  if not v2.my_school(sid) then return false; end if;
  if p_write then
    return v2.my_role() in ('principal','deputy_students','deputy','deputy_academic')
        or split_part(p_path,'/',3) = 'sign';   -- توقيعُ المرء يرفعه بنفسه
  end if;
  return true;
end $function$
;
