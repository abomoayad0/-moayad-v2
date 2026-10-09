-- v2.my_post_keys()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 36d2031b14d4f2b80e9dd0374f4e3492
CREATE OR REPLACE FUNCTION v2.my_post_keys()
 RETURNS text[]
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce(array_agg(distinct k), '{}'::text[]) from (
    select post_key k from v2.my_posts()
    union select v2.my_role()
    union select u.role from v2.app_users u where u.id = auth.uid() and u.is_active
  ) t where k is not null;
$function$
;
