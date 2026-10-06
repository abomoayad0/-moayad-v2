-- v2.assert_grant(p_allowed text[], p_what text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1f3b9b5af491b45010764971ca9ad872
CREATE OR REPLACE FUNCTION v2.assert_grant(p_allowed text[], p_what text)
 RETURNS void
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare g text;
begin
  if auth.uid() is null then
    raise exception 'لا بدّ من تسجيل الدخول — ولا يُقبل % بلا هويّة', p_what; end if;
  g := v2.my_grant();
  if g is null then
    raise exception 'لا حسابَ فعّالٌ لك في هذا النظام — ولا يُقبل %', p_what; end if;
  if not (g = any(p_allowed)) then
    raise exception 'صلاحيتك (%) لا تملك %', g, p_what; end if;
end $function$
;
