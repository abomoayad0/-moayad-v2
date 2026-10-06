-- v2.fn_behavior_balance(p_student uuid, p_year uuid, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3f039be3099b70c4e9a2c5c132072ec2
CREATE OR REPLACE FUNCTION v2.fn_behavior_balance(p_student uuid, p_year uuid, p_term smallint)
 RETURNS numeric
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
  select least(100, greatest(0, coalesce(sum(points),0)))
  from v2.behavior_ledger
  where student_id=p_student and year_id=p_year and term_no=p_term;
$function$
;
