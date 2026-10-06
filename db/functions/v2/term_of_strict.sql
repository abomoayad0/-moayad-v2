-- v2.term_of_strict(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ba23d6abe723f44bff4f35b3d1dd9a11
CREATE OR REPLACE FUNCTION v2.term_of_strict(p_school uuid, p_date date)
 RETURNS smallint
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce(
    -- ① فصلُ المدرسة إن أسّسته
    (select t.number from v2.terms t
       join v2.academic_years y on y.id = t.year_id
      where y.school_id = p_school and p_date between t.starts_on and t.ends_on
      limit 1),
    -- ② وإلّا التقويمُ الوزاريُّ
    (select w.term_no from v2.calendar_days d
       join v2.calendar_weeks w on w.id = d.week_id
       join v2.calendar_years y on y.id = d.year_id
       join v2.schools s on s.calendar_scope = y.scope_key
      where s.id = p_school and d.on_g = p_date limit 1)
  )::smallint;
$function$
;
