-- v2.fn_term_of(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 bed64fa816b314eea14b01c93a119d37
CREATE OR REPLACE FUNCTION v2.fn_term_of(p_school uuid, p_date date)
 RETURNS smallint
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce(
    v2.term_of_strict(p_school, p_date),
    (select b.term_no from (
        select w.term_no, min(w.from_g) f, max(w.to_g) t
          from v2.calendar_weeks w
          join v2.calendar_years y on y.id = w.year_id
          join v2.schools s on s.calendar_scope = y.scope_key
         where s.id = p_school
         group by w.term_no) b
      order by least(abs(p_date - b.f), abs(p_date - b.t)) limit 1),
    1)::smallint;
$function$
;
