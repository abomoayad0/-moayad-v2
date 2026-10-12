-- v2.loyalty_section(p_school uuid, p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ec120b1cf06e27fc1e6d5eded56b74e3
CREATE OR REPLACE FUNCTION v2.loyalty_section(p_school uuid, p_student uuid)
 RETURNS uuid
 LANGUAGE sql
 STABLE
AS $function$
  select cs.id
    from v2.enrolments e
    join v2.class_sections cs
      on cs.school_id = e.school_id and cs.grade = e.grade and cs.section = e.section
   where e.student_id = p_student and e.school_id = p_school and e.ended_on is null
   order by e.created_at desc nulls last
   limit 1
$function$
;
