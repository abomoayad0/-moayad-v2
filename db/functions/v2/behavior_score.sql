-- v2.behavior_score(p_student uuid, p_year uuid, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3f13ca56be73e2a72946bb8e25bce5e2
CREATE OR REPLACE FUNCTION v2.behavior_score(p_student uuid, p_year uuid, p_term smallint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  with l as (select * from v2.behavior_ledger
              where student_id=p_student and year_id=p_year and term_no=p_term),
  s as (select
    coalesce((select sum(points) from l where kind='opening'),80)      as opening,
    coalesce(-(select sum(points) from l where kind='deduction'),0)    as deducted,
    coalesce((select sum(points) from l where kind='compensation'),0)  as restored,
    coalesce((select sum(points) from l where kind='merit'),0)         as merit,
    coalesce(-(select sum(points) from l where kind='veto'),0)         as veto)
  select jsonb_build_object(
    'opening',  s.opening,
    'deducted', s.deducted,
    'restored', s.restored,
    'positive', least(s.opening - s.deducted + s.restored, 80),
    'merit',    least(s.merit, 20),
    'total',    least(least(s.opening - s.deducted + s.restored, 80) + least(s.merit, 20), 100))
  from s;
$function$
;
