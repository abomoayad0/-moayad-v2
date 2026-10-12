-- v2.loyalty_balance(p_school uuid, p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 593349378749ac9cf3d84eb0a9e6fabe
CREATE OR REPLACE FUNCTION v2.loyalty_balance(p_school uuid, p_student uuid)
 RETURNS integer
 LANGUAGE sql
 STABLE
AS $function$
  select coalesce(sum(case when kind = 'earn' then points else -points end), 0)::int
    from v2.loyalty_ledger
   where school_id = p_school and student_id = p_student and voided_at is null
$function$
;
