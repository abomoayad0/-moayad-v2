-- v2.assert_role(p_allowed text[], p_what text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 863207a79f7458005708c281931aa906
CREATE OR REPLACE FUNCTION v2.assert_role(p_allowed text[], p_what text)
 RETURNS void
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare g text; r text; mine text[]; chosen text; allowed_ar text;
begin
  if auth.uid() is null then return; end if;
  g := v2.my_grant();
  if g = 'viewer' then raise exception 'صلاحيتك اطّلاع فقط — لا يُقبل %', p_what; end if;
  select role_key into chosen from v2.session_role where user_id = auth.uid();
  r := v2.my_role();
  select string_agg(coalesce(v2.role_ar(x),x),' أو ') into allowed_ar from unnest(p_allowed) x;

  if chosen is not null then
    if r = any (p_allowed) then return; end if;
    raise exception 'أنت تعمل الآن بصفة «%» ولا تملك %. وهذا لـ%.',
      coalesce(v2.role_ar(r),r), p_what, allowed_ar;
  end if;

  if g in ('owner','admin') then return; end if;
  select array_agg(post_key) into mine from v2.my_posts();
  if r = any (p_allowed) or (mine && p_allowed) then return; end if;
  raise exception 'تكليفك (%) لا يملك %. وهذا لـ%.',
    coalesce(v2.role_ar(r),'بلا تكليف'), p_what, allowed_ar;
end $function$
;
