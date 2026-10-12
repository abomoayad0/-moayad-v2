-- public.v2_school_card(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 27dafbd3dc498c29c6b5e5d14d31a952
CREATE OR REPLACE FUNCTION public.v2_school_card(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception '%', v2.not_my_school_ar(); end if;
  select jsonb_build_object(
    'school',s.id,'name',s.name_ar,'stage',s.stage,'category',s.category,
    'structure',s.structure_code,'calendar_scope',s.calendar_scope,
    'test_mode',s.test_mode,'active',s.is_active,
    'sections',(select count(*) from v2.class_sections c where c.school_id=s.id),
    'students',(select count(*) from v2.enrolments e
                 where e.school_id=s.id and e.status='active'),
    'staff',(select count(distinct a.person_id) from v2.assignments a
              where a.school_id=s.id and a.ended_on is null))
  into r from v2.schools s where s.id=p_school;
  return r;
end $function$
;
