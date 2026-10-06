-- v2.evidence_path_for(p_entry uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 70cdf673f9dd0b2faa64393b1d36cce3
CREATE OR REPLACE FUNCTION v2.evidence_path_for(p_entry uuid)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select 'merit/'||o.school_id||'/'||x.student_id||'/'||x.id||'/'
  from v2.merit_entries x join v2.merit_opportunities o on o.id=x.opp_id
  where x.id = p_entry;
$function$
;
