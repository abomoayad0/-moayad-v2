-- public.v2_drafts_list(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7f9dfb560fc1fc0f8247c1031722b57e
CREATE OR REPLACE FUNCTION public.v2_drafts_list(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'id',d.id,'state',d.state,'made_at',d.made_at,'applied_at',d.applied_at,
      'made_by',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=d.made_by),
      'note',d.note_ar,'stats',d.stats) order by d.made_at desc),'[]'::jsonb)
  into r from v2.timetable_drafts d where d.school_id=p_school;
  return r;
end $function$
;
