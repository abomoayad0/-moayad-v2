-- public.v2_exception_kinds()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ed93b701713e29517db3b30a57f41e3e
CREATE OR REPLACE FUNCTION public.v2_exception_kinds()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select jsonb_agg(jsonb_build_object('key',k,'label',l))
  from (values
    ('conduct','قواعد السلوك والمواظبة'),
    ('attendance','الحضور والغياب'),
    ('committee','اللجان وتشكيلها'),
    ('calendar','التقويم الدراسي'),
    ('structure','الهيكل التنظيمي'),
    ('staffing','الملاك والتكاليف'),
    ('grading','التقدير والدرجات'),
    ('other','أخرى')) t(k,l);
$function$
;
