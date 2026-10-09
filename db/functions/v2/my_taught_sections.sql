-- v2.my_taught_sections(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 22941fb6d41b1977e7894a4d7b6f90a9
CREATE OR REPLACE FUNCTION v2.my_taught_sections(p_school uuid)
 RETURNS TABLE(grade smallint, section text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select distinct ta.grade, ta.section
    from v2.teaching_assignments ta
   where ta.school_id = p_school and ta.person_id = v2.current_person()
     and ta.section is not null
  union
  select distinct cs.grade, cs.section
    from v2.timetable tt
    join v2.class_sections cs on cs.id = tt.section_id
   where tt.school_id = p_school and tt.person_id = v2.current_person()
     and cs.section is not null
$function$
;
