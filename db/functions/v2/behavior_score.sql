-- v2.behavior_score(p_student uuid, p_year uuid, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5393a8901bdd74996b0b26040574f4b7
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
    coalesce((select sum(points) from l where kind='veto'),0)          as vetoed),
  c as (select s.*,
    least(s.opening - s.deducted + s.vetoed + s.restored, 80) as raw from s)
  select jsonb_build_object(
    'opening',  c.opening,
    'deducted', c.deducted,
    'vetoed',   c.vetoed,
    'deducted_net', c.deducted - c.vetoed,
    'restored', c.restored,
    -- 🔑 أرضٌ عند الصفر: الدرجةُ وعاءٌ سعتُه ثمانون، ولا يكون فيه أقلُّ من فراغه
    'positive', greatest(c.raw, 0),
    'below_floor', case when c.raw < 0 then -c.raw else 0 end,
    'merit',    least(c.merit, 20),
    'total',    greatest(least(greatest(c.raw,0) + least(c.merit,20), 100), 0))
  from c;
$function$
;
