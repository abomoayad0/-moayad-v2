-- v2.current_person()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d588322de9af5c672709a4b87cabc6da
CREATE OR REPLACE FUNCTION v2.current_person()
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select person_id from v2.app_users where id = auth.uid() and is_active
$function$
;
