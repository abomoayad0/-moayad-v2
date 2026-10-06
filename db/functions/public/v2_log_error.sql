-- public.v2_log_error(p jsonb)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a48dc3b913a1217aa4e78e8f6ba0481a
CREATE OR REPLACE FUNCTION public.v2_log_error(p jsonb)
 RETURNS uuid
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select v2.fn_log_error(
    coalesce(p->>'message','(بلا نص)'), p->>'fn', p->>'screen', p->>'action',
    case when p ? 'params' then p->'params' else null end,
    p->>'sqlstate', p->>'detail', p->>'hint', p->>'context',
    coalesce(p->>'source','screen'), coalesce(p->>'kind','error'),
    p->>'ua', p->>'url')
$function$
;
