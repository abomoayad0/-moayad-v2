-- v2.loyalty_reward(p_school uuid, p_code text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2907ae2b854346a19df1e27b7b0ffcb9
CREATE OR REPLACE FUNCTION v2.loyalty_reward(p_school uuid, p_code text)
 RETURNS v2.loyalty_rewards
 LANGUAGE sql
 STABLE
AS $function$
  select * from v2.loyalty_rewards
   where code = p_code and active and (school_id = p_school or school_id is null)
   order by (school_id is null)
   limit 1
$function$
;
