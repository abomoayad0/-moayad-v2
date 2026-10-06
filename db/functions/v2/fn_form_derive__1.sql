-- v2.fn_form_derive(p_form smallint, p_data jsonb)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1bba3a54ec4baac63488a1f630a481a7
CREATE OR REPLACE FUNCTION v2.fn_form_derive(p_form smallint, p_data jsonb)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
select coalesce(p_data,'{}'::jsonb) || coalesce((
  select jsonb_object_agg(s.key, public.v2_weekday((p_data->>s.derived_from)::date))
  from v2.form_schema s
  where s.form_no=p_form and s.input='derived' and s.derived_from is not null
    and nullif(p_data->>s.derived_from,'') is not null),'{}'::jsonb)
$function$
;
