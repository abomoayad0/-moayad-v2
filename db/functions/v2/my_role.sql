-- v2.my_role()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4dde033380dd755b0496a86ddb26a958
CREATE OR REPLACE FUNCTION v2.my_role()
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce(
    (select role_key from v2.session_role where user_id = auth.uid()),
    (select mp.post_key from v2.my_posts() mp where mp.is_assignment
      order by case mp.post_key when 'principal' then 1 when 'deputy' then 2
        when 'deputy_students' then 3 when 'deputy_academic' then 4 when 'deputy_school' then 5
        when 'admin_assistant' then 6 when 'admin_assistant_students' then 6
        when 'info_registrar' then 7 else 9 end limit 1),
    (select pe.post_key from v2.app_users u join v2.people pe on pe.id=u.person_id
      where u.id = auth.uid() and u.is_active limit 1))
$function$
;
