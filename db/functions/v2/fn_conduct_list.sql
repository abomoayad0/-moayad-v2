-- v2.fn_conduct_list(p_stage text, p_mode text, p_target text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e6b8652e0b25dfd3dca31ce69d10b5e4
CREATE OR REPLACE FUNCTION v2.fn_conduct_list(p_stage text DEFAULT NULL::text, p_mode text DEFAULT 'onsite'::text, p_target text DEFAULT 'general'::text)
 RETURNS TABLE(id integer, text_ar text, degree_no smallint, stage_scope text, mode text, target text, source_page text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select p.id, p.text_ar, p.degree_no, p.stage_scope, p.mode, p.target, p.source_page
  from v2.conduct_problems p
  where (p_stage is null or p.stage_scope = p_stage) and p.mode = p_mode and p.target = p_target
  order by p.degree_no, p.id
$function$
;
