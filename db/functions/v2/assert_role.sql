-- v2.assert_role(p_allowed text[], p_what text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 30a6d328baebe672f05c8aa7328069a8
CREATE OR REPLACE FUNCTION v2.assert_role(p_allowed text[], p_what text)
 RETURNS void
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare g text; r text; mine text[]; chosen text; allowed_ar text; sc uuid;
begin
  if auth.uid() is null then
    raise exception 'لا بدّ من تسجيل الدخول — ولا يُقبل % بلا هويّة', p_what; end if;
  g := v2.my_grant();
  if g is null then
    raise exception 'لا حسابَ فعّالٌ لك في هذا النظام — ولا يُقبل %', p_what; end if;
  if g = 'viewer' then raise exception 'صلاحيتك اطّلاع فقط — لا يُقبل %', p_what; end if;
  if g = 'owner' then return; end if;

  select role_key into chosen from v2.session_role where user_id = auth.uid();
  r := v2.my_role();
  select string_agg(coalesce(v2.role_ar(x),x),' أو ') into allowed_ar from unnest(p_allowed) x;

  -- 🔑 الإنابةُ النافذةُ تُقبل ولو لم تكن صفتَه الأصليّة
  sc := v2.acting_school();
  if sc is not null and exists (
       select 1 from v2.delegations d
        where d.to_person = v2.current_person() and d.school_id = sc
          and d.post_key = any(p_allowed) and d.revoked_at is null
          and d.starts_on <= current_date
          and (d.ends_on is null or d.ends_on >= current_date)) then
    return; end if;

  if chosen is not null then
    if r = any (p_allowed) then return; end if;
    raise exception 'أنت تعمل الآن بصفة «%» ولا تملك %. وهذا لـ% — أو لمن أُنيب عنه.',
      coalesce(v2.role_ar(r),r), p_what, allowed_ar;
  end if;

  if g = 'admin' then return; end if;
  select array_agg(post_key) into mine from v2.my_posts();
  if r = any (p_allowed) or (mine && p_allowed) then return; end if;
  raise exception 'تكليفك (%) لا يملك %. وهذا لـ% — أو لمن أُنيب عنه.',
    coalesce(v2.role_ar(r),'بلا تكليف'), p_what, allowed_ar;
end $function$
;
