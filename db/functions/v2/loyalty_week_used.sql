-- v2.loyalty_week_used(p_school uuid, p_student uuid, p_code text, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 11b960e225d2a8e78400855c897eb18c
CREATE OR REPLACE FUNCTION v2.loyalty_week_used(p_school uuid, p_student uuid, p_code text, p_date date)
 RETURNS integer
 LANGUAGE sql
 STABLE
AS $function$
  select coalesce(sum(points), 0)::int
    from v2.loyalty_ledger
   where school_id = p_school and student_id = p_student
     and source_code = p_code and voided_at is null
     and on_date between v2.loyalty_week_start(p_date) and v2.loyalty_week_start(p_date) + 6
$function$
;
