-- v2.staff_late_tally(p_school uuid, p_person uuid, p_fy smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 eda7e29aed1f14f934e58f08b24f7015
CREATE OR REPLACE FUNCTION v2.staff_late_tally(p_school uuid, p_person uuid, p_fy smallint)
 RETURNS TABLE(days_n integer, minutes_total integer, hours_txt text, notice_due boolean, notice_n integer, deduct_days_due integer, deduct_days_done integer, excused_n integer, last_on date, notice_hours integer, per_hours integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  with r as (select v2.rule_n(p_school,'staff_notice_hours') nh,
                    v2.rule_n(p_school,'staff_deduct_per_hours') ph),
  l as (select * from v2.staff_lateness sl
         where sl.school_id=p_school and sl.person_id=p_person
           and sl.fiscal_year=p_fy and sl.voided_at is null),
  c as (select coalesce(sum(minutes_late),0)::int m, count(*)::int n, max(on_date) d
          from l where excuse_state <> 'accepted'),
  e as (select count(*)::int n from l where excuse_state = 'accepted'),
  a as (select count(*) filter (where kind='notice')::int notices,
               coalesce(sum(days) filter (where kind='deduction'),0)::int ddays
          from v2.staff_late_actions where school_id=p_school and person_id=p_person
            and fiscal_year=p_fy and voided_at is null)
  select c.n, c.m,
    case when c.m = 0 then 'لا تأخّر'
         else trim(
           case when c.m/60 > 0 then v2.ar_count(c.m/60,'ساعةٌ واحدة','ساعتان','ساعاتٍ','ساعةً') else '' end
           || case when c.m/60 > 0 and c.m%60 > 0 then ' و' else '' end
           || case when c.m%60 > 0 then v2.ar_count(c.m%60,'دقيقةٌ واحدة','دقيقتان','دقائقَ','دقيقةً') else '' end)
    end,
    c.m >= (select nh*60 from r),
    a.notices,
    (c.m / (select ph*60 from r))::int,
    a.ddays,
    e.n, c.d,
    (select nh from r), (select ph from r)
  from c, e, a
$function$
;
