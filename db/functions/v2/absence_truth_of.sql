-- v2.absence_truth_of(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a1a3ee77ab902eb7ed32725899c4909d
CREATE OR REPLACE FUNCTION v2.absence_truth_of(p_school uuid)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select coalesce((select r.absence_truth from v2.conduct_school_rules r
                    where r.school_id = p_school), 'system');
$function$
;
