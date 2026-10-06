-- v2.fn_is_excused(p_student uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 461052c62757749a95f9ea975cfe15cd
CREATE OR REPLACE FUNCTION v2.fn_is_excused(p_student uuid, p_date date)
 RETURNS boolean
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
  select exists (select 1 from v2.absence_excuse_claims c
    where c.student_id=p_student and c.decision='accepted'
      and p_date between c.from_date and c.to_date);
$function$
;
