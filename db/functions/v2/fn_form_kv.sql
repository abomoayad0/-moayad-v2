-- v2.fn_form_kv(p_form smallint, p_doc jsonb, p_data jsonb)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c28504d3484b0386c6afee9816d44db1
CREATE OR REPLACE FUNCTION v2.fn_form_kv(p_form smallint, p_doc jsonb, p_data jsonb)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
select coalesce(jsonb_agg(jsonb_build_object('label', s.label_ar,
  'value', case
    when s.input='auto' then (v2.fn_form_auto(p_form,p_doc))->>s.key
    when s.input='date' and nullif(p_data->>s.key,'') is not null
      then v2.fn_to_hijri((p_data->>s.key)::date)||' هـ'
    else p_data->>s.key end) order by s.ord),'[]'::jsonb)
from v2.form_schema s where s.form_no=p_form
$function$
;
