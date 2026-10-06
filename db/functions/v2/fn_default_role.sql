-- v2.fn_default_role()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 65483ac0d0d4844a4edc542d18bcc868
CREATE OR REPLACE FUNCTION v2.fn_default_role()
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r record;
begin
  if exists (select 1 from v2.session_role where user_id=auth.uid()) then
    return (select v2.role_ar(role_key) from v2.session_role where user_id=auth.uid()); end if;
  select x.role_key, x.school_id into r from v2.fn_my_roles() x
   where x.source='تكليف'
   order by case x.role_key when 'principal' then 1 when 'deputy' then 2
     when 'deputy_students' then 3 when 'deputy_academic' then 4 when 'deputy_school' then 5
     when 'admin_assistant' then 6 when 'info_registrar' then 7 when 'counselor' then 8 else 9 end,
     x.school_ar limit 1;
  if r.role_key is null then
    select x.role_key, x.school_id into r from v2.fn_my_roles() x limit 1; end if;
  if r.role_key is null then return null; end if;
  return v2.fn_act_as(r.role_key, r.school_id);
end $function$
;
