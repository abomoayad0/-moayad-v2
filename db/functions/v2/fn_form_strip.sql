-- v2.fn_form_strip(p_form smallint, p_data jsonb)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d062f203e87ae9aded90afdc2569a64a
CREATE OR REPLACE FUNCTION v2.fn_form_strip(p_form smallint, p_data jsonb)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
select coalesce(jsonb_object_agg(k, p_data->k),'{}'::jsonb)
from jsonb_object_keys(coalesce(p_data,'{}'::jsonb)) k
where k not in (select key from v2.form_schema where form_no=p_form and input in ('auto','derived'))
$function$
;
