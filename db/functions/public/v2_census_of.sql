-- public.v2_census_of(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2d3b21b7d1010695ae60694e56b84113
CREATE OR REPLACE FUNCTION public.v2_census_of(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  perform v2.assert_my_student(p_student,'حصر السلوكيات');
  select coalesce(jsonb_agg(jsonb_build_object(
      'census',c.id,'state',c.state,'assigned_at',c.assigned_at::date,'due',c.due_on,
      'to',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=c.assigned_to),
      'by',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=c.assigned_by),
      'positives',c.positives,'negatives',c.negatives,'causes',c.causes,
      'suggestion',c.suggestion,'filed_at',c.filed_at,'returned_why',c.returned_why)
      order by c.assigned_at desc),'[]'::jsonb)
  into r from v2.behavior_census c where c.student_id=p_student;
  return r;
end $function$
;
