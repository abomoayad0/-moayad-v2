-- v2.fn_teaching_load(p_person uuid, p_year uuid, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d444ef10cd7664667293a5e9b2e86f5e
CREATE OR REPLACE FUNCTION v2.fn_teaching_load(p_person uuid, p_year uuid, p_term smallint DEFAULT NULL::smallint)
 RETURNS TABLE("المعلم" text, "الرتبة" text, "النصاب_المقرر" smallint, "النصاب_الفعلي" integer, "الفرق" integer, "حصص_انتظار" integer, "خارج_التخصص" integer, "الحكم" text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
with p as (select pe.*, r.label_ar rl,
             case when exists (select 1 from v2.assignments a where a.person_id=pe.id and a.post_key='sped_teacher' and a.ended_on is null)
                  then r.periods_sen else r.periods_general end quota
           from v2.people pe left join v2.teaching_ranks r on r.key=pe.rank_key where pe.id=p_person),
t as (select coalesce(sum(periods_n),0)::int tot,
             coalesce(sum(periods_n) filter (where is_waiting),0)::int wait,
             coalesce(sum(periods_n) filter (where out_of_major),0)::int oom
      from v2.teaching_assignments where person_id=p_person and year_id=p_year
        and (p_term is null or term_no is not distinct from p_term))
select p.full_name, coalesce(p.rl,'— لا رتبة'), p.quota, t.tot,
  t.tot - coalesce(p.quota,0), t.wait, t.oom,
  case when p.quota is null then 'لا رتبة مسجّلة — لا يُحسب النصاب'
       when t.tot = p.quota then 'مكتمل'
       when t.tot < p.quota then 'أقل من النصاب بـ'||(p.quota-t.tot)||' حصة'
       else 'يزيد على النصاب بـ'||(t.tot-p.quota)||' حصة' end
from p, t;
$function$
;
