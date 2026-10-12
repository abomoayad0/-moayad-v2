-- v2.badge_of(p_school uuid, p_code text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 92231c9b0c3c80094f839eca9b47fb3d
CREATE OR REPLACE FUNCTION v2.badge_of(p_school uuid, p_code text)
 RETURNS v2.loyalty_badges
 LANGUAGE sql
 STABLE
AS $function$
  select * from v2.loyalty_badges
   where code = p_code and active and (school_id = p_school or school_id is null)
   order by (school_id is null) limit 1
$function$
;
