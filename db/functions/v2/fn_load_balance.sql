-- v2.fn_load_balance(p_school uuid, p_year uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a490ad285d736a4db7840145df09b3c4
CREATE OR REPLACE FUNCTION v2.fn_load_balance(p_school uuid, p_year uuid)
 RETURNS TABLE("المعلم" text, "الرتبة" text, "المقرر" smallint, "الفعلي" integer, "الفرق" integer, "أولوية_المناوبة" integer, "مستثنى" text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
with t as (
  select pe.id, pe.full_name, r.label_ar rl, r.periods_general q,
    coalesce((select sum(ta.periods_n) from v2.teaching_assignments ta
              where ta.person_id=pe.id and ta.year_id=p_year),0)::int tot,
    pe.is_seconded_partial,
    exists (select 1 from v2.assignments a where a.person_id=pe.id and a.ended_on is null
            and a.post_key in ('principal','deputy','deputy_academic','deputy_school','deputy_students',
                               'deputy_academic_school','deputy_school_students')) is_leader
  from v2.people pe
  join v2.assignments a on a.person_id=pe.id and a.school_id=p_school and a.ended_on is null
  left join v2.teaching_ranks r on r.key=pe.rank_key
  group by pe.id, pe.full_name, r.label_ar, r.periods_general, pe.is_seconded_partial)
select full_name, coalesce(rl,'— لا رتبة'), q, tot, tot-coalesce(q,0),
  case when is_leader or is_seconded_partial then null
       else rank() over (order by tot - coalesce(q,0)) end::int,
  case when is_leader then 'مدير أو وكيل — مستثنى بنصّ ض01'
       when is_seconded_partial then 'منتدب انتداباً جزئياً — مستثنى بنصّ ض01'
       else null end
from t order by 5;
$function$
;
