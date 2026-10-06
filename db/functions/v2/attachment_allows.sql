-- v2.attachment_allows(p_path text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6749f90f62dce6ed0aaf9648c742ab2b
CREATE OR REPLACE FUNCTION v2.attachment_allows(p_path text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select exists (select 1 from v2.attachments a
    where a.storage_path = p_path and v2.my_school(a.school_id));
$function$
;
