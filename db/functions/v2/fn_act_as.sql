-- v2.fn_act_as(p_role text, p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 fc5594cff4c38be18c6ad544425cc35f
CREATE OR REPLACE FUNCTION v2.fn_act_as(p_role text, p_school uuid DEFAULT NULL::uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare ok boolean;
begin
  select exists (select 1 from v2.fn_my_roles() r
    where r.role_key = p_role and (p_school is null or r.school_id is not distinct from p_school))
   into ok;
  if not ok then raise exception 'ليست من صفاتك: %', coalesce(v2.role_ar(p_role),p_role); end if;
  insert into v2.session_role (user_id, role_key, school_id) values (auth.uid(), p_role, p_school)
  on conflict (user_id) do update set role_key=excluded.role_key, school_id=excluded.school_id, chosen_at=now();
  return 'تعمل الآن بصفة: '||v2.role_ar(p_role)||coalesce(' — '||(select name_ar from v2.schools where id=p_school),'');
end $function$
;
