-- public.v2_plan_remove(p_school uuid, p_plan uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3551f51db5e9ca9ad8b67370a2b53f35
CREATE OR REPLACE FUNCTION public.v2_plan_remove(p_school uuid, p_plan uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_role(array['principal','deputy_academic','deputy'],'ضبطَ خطّة المواد');
  update v2.subject_plan set active=false where id=p_plan and school_id=p_school;
  if not found then raise exception 'هذي الخطّةُ ليست لمدرستك'; end if;
  return jsonb_build_object('ok',true);
end $function$
;
