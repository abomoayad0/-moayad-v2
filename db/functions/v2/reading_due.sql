-- v2.reading_due(p_school uuid, p_person uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 0ad6e5ba90335149655fb019cedcf90e
CREATE OR REPLACE FUNCTION v2.reading_due(p_school uuid, p_person uuid, p_date date)
 RETURNS TABLE(eligible_n integer, required_n integer, done_n integer, skipped_n integer, missing_n integer, per_day integer, minutes integer, g_from integer, g_to integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  with r as (select v2.rule_n(p_school,'reading_periods_per_day') pd,
                    v2.rule_n(p_school,'reading_minutes_per_period') mn,
                    v2.rule_n(p_school,'reading_grade_from') gf,
                    v2.rule_n(p_school,'reading_grade_to') gt),
  e as (select ep.period_no, ep.section_id
          from v2.effective_periods(p_school, p_person, p_date) ep
          join v2.class_sections cs on cs.id = ep.section_id, r
         where cs.grade between r.gf and r.gt),
  s as (select rs.period_no, rs.done from v2.reading_sessions rs
         where rs.school_id=p_school and rs.person_id=p_person
           and rs.on_date=p_date and rs.voided_at is null)
  select (select count(*)::int from e),
         least((select count(*) from e), (select pd from r))::int,
         (select count(*)::int from s where done),
         (select count(*)::int from s where not done),
         greatest(0, least((select count(*) from e), (select pd from r))
                     - (select count(*) from s))::int,
         (select pd from r), (select mn from r), (select gf from r), (select gt from r)
$function$
;
