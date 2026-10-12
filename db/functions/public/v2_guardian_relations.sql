-- public.v2_guardian_relations()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 41d92a83c7a005e6cbeb4f2ef3d0bb66
CREATE OR REPLACE FUNCTION public.v2_guardian_relations()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select jsonb_build_object(
    'rows', coalesce((select jsonb_agg(jsonb_build_object(
        'label_ar', g.label_ar, 'source_ar', g.source_ar) order by g.ord, g.label_ar)
      from v2.guardian_relations g where g.active), '[]'::jsonb),
    'note_ar', 'الصلةُ تُختار من هذا الفهرس · ولا تُكتب يدًا كي لا تتفرّق الأسماءُ على الطالب الواحد');
$function$
;
