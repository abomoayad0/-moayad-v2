-- v2.practice_day_used(p_school uuid, p_student uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 03165d5aa183d77d208099c368454318
CREATE OR REPLACE FUNCTION v2.practice_day_used(p_school uuid, p_student uuid, p_date date)
 RETURNS numeric
 LANGUAGE sql
 STABLE
AS $function$
  select coalesce(sum(abs(pp.points)),0)::numeric
    from v2.practice_points pp
    join v2.practice_records r on r.id = pp.record_id
   where pp.school_id = p_school and pp.student_id = p_student
     and r.on_date = p_date and r.undone_at is null
$function$
;
