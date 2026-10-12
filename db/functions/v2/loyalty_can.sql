-- v2.loyalty_can(p_who text[])
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1f81e2363036f98483342001f1d400d9
CREATE OR REPLACE FUNCTION v2.loyalty_can(p_who text[])
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
AS $function$
declare g text; sc uuid;
begin
  if auth.uid() is null then return false; end if;
  g := v2.my_grant();
  if g is null or g = 'viewer' then return false; end if;
  if g in ('owner','admin') then return true; end if;
  if v2.my_role() = any (p_who) then return true; end if;
  if exists (select 1 from v2.my_posts() mp where mp.post_key = any (p_who)) then return true; end if;
  sc := v2.acting_school();
  return sc is not null and exists (
    select 1 from v2.delegations d
     where d.to_person = v2.current_person() and d.school_id = sc
       and d.post_key = any (p_who) and d.revoked_at is null
       and d.starts_on <= current_date and (d.ends_on is null or d.ends_on >= current_date));
end $function$
;
