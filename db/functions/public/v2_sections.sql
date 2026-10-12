-- public.v2_sections(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 03e96f99f5bf8595e1fb7d4424755e0e
CREATE OR REPLACE FUNCTION public.v2_sections(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception '%', v2.not_my_school_ar(); end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'id',c.id,'grade',c.grade,'grade_ar',v2.ar_num(c.grade),
      'section',c.section,'label',coalesce(c.label_ar, c.grade||'/'||c.section),
      'room',c.room_ar,'capacity',c.capacity,'active',c.active,
      'homeroom',(select v2.fn_display_name(p.full_name) from v2.people p
                   where p.id=c.homeroom_person),
      'students',(select count(*) from v2.enrolments e
                   where e.school_id=p_school and e.status='active'
                     and e.grade=c.grade and e.section=c.section))
      order by c.grade, c.section),'[]'::jsonb)
  into r from v2.class_sections c where c.school_id=p_school and c.active;
  return r;
end $function$
;
