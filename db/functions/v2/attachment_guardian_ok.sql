-- v2.attachment_guardian_ok(p_path text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6a592decbc5ca4b5bb9f88e48c8b66de
CREATE OR REPLACE FUNCTION v2.attachment_guardian_ok(p_path text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select exists (select 1 from v2.attachments a
    join v2.guardians g on g.id = a.guardian_id
    where a.storage_path = p_path and g.user_id = auth.uid() and g.portal_active);
$function$
;
