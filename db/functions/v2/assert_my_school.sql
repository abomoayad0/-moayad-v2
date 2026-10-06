-- v2.assert_my_school(p_school uuid, p_what text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 dcbfd127be60e945f062d1ffccbe0a07
CREATE OR REPLACE FUNCTION v2.assert_my_school(p_school uuid, p_what text)
 RETURNS void
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sr uuid; rk text;
begin
  if auth.uid() is null then return; end if;
  if p_school is null then raise exception 'لا مدرسة محدّدة — %', p_what; end if;
  if not v2.my_school(p_school) then
    raise exception 'هذه المدرسة ليست من مدارسك — لا يُقبل %', p_what; end if;
  select school_id, role_key into sr, rk from v2.session_role where user_id = auth.uid();
  if sr is not null and sr <> p_school then
    raise exception 'أنت تعمل بصفة «%» في «%» — ولا يقع % في مدرسة أخرى. بدّل صفتك.',
      v2.role_ar(rk), (select name_ar from v2.schools where id=sr), p_what;
  end if;
end $function$
;
