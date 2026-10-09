-- v2.denial_limit(p_year_days integer)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 aa6a2345ca3933ffdd5616ddb7159ae3
CREATE OR REPLACE FUNCTION v2.denial_limit(p_year_days integer)
 RETURNS integer
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select case when coalesce(p_year_days,0) = 0 then null
              else floor(p_year_days * (select value_num from v2.conduct_rules
                                         where key='attendance.denial_pct') / 100.0)::int + 1 end;
$function$
;
