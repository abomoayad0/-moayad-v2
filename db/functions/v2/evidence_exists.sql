-- v2.evidence_exists(p_path text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8ec82f925f0910d23159ac6f2bc8f95e
CREATE OR REPLACE FUNCTION v2.evidence_exists(p_path text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'storage', 'public'
AS $function$
  select exists (select 1 from storage.objects
    where bucket_id = 'v2-attachments' and name = p_path);
$function$
;
