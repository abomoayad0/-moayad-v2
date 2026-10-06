-- public.v2_posts_list()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ed8e6af6b7e0907af02d5b932fbc4d65
CREATE OR REPLACE FUNCTION public.v2_posts_list()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce(jsonb_agg(jsonb_build_object(
    'key',p.key,'label',p.label_ar,'kind',p.kind,'source',p.source_page)
    order by p.label_ar),'[]'::jsonb) from v2.posts p;
$function$
;
