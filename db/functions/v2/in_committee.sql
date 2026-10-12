-- v2.in_committee(p_school uuid, p_key text, p_person uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 75e89ea423c8e8f0db820597671e1a84
CREATE OR REPLACE FUNCTION v2.in_committee(p_school uuid, p_key text, p_person uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select exists (select 1 from v2.committee_members m
                  where m.school_id = p_school and m.committee_key = p_key
                    and m.person_id = p_person and m.ended_on is null)
$function$
;
