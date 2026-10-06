-- v2.acting_school()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 671c8602f2154cb5a62d2860fedd2df9
CREATE OR REPLACE FUNCTION v2.acting_school()
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce(
    (select sr.school_id from v2.session_role sr where sr.user_id = auth.uid()),
    (select u.school_id  from v2.app_users u where u.id = auth.uid() and u.is_active));
$function$
;
