-- v2.fn_form_derive(p_form smallint, p_data jsonb, p_doc jsonb)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ab4bd0ea6d92c467422cbaab17144bd3
CREATE OR REPLACE FUNCTION v2.fn_form_derive(p_form smallint, p_data jsonb, p_doc jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
select coalesce(p_data,'{}'::jsonb) || coalesce((
  select jsonb_object_agg(s.key, case s.derive_kind
    when 'weekday' then public.v2_weekday((p_data->>s.derived_from)::date)
    when 'age' then public.v2_age_ar((p_doc#>>'{student,birth_g}')::date)
    else null end)
  from v2.form_schema s
  where s.form_no=p_form and s.input='derived'
    and (s.derive_kind='age' or nullif(p_data->>s.derived_from,'') is not null)),'{}'::jsonb)
$function$
;
