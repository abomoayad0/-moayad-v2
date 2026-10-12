-- v2.leads_school(p_extra text[])
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 950aad41bd55414d22bb22d096e38582
CREATE OR REPLACE FUNCTION v2.leads_school(p_extra text[] DEFAULT '{}'::text[])
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
AS $function$
declare g text; allowed text[];
begin
  if auth.uid() is null then return false; end if;
  g := v2.my_grant();
  if g is null or g = 'viewer' then return false; end if;
  if g = 'owner' then return true; end if;              -- المالكُ فوق الجميع
  allowed := array['principal'] || coalesce(p_extra, '{}');
  if v2.my_role() = any (allowed) then return true; end if;
  return exists (select 1 from v2.my_posts() mp where mp.post_key = any (allowed));
end $function$
;
