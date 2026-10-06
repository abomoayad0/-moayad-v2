-- v2.fn_form_rows(p_form smallint, p_doc jsonb)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 536119cc11b678a9f5fc5b47d4c1fe73
CREATE OR REPLACE FUNCTION v2.fn_form_rows(p_form smallint, p_doc jsonb)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
select case p_form
  when 5 then coalesce(p_doc->'rows','[]'::jsonb)
  when 6 then coalesce(p_doc->'rows','[]'::jsonb)
  when 15 then coalesce((select jsonb_agg(jsonb_build_object(
      'on_date', d->>'on_h', 'weekday', d->>'weekday_ar') )
    from jsonb_array_elements(coalesce(p_doc->'days','[]'::jsonb)) d),'[]'::jsonb)
  when 16 then coalesce((select jsonb_agg(jsonb_build_object(
      'on_date', d->>'on_h', 'weekday', d->>'weekday_ar') )
    from jsonb_array_elements(coalesce(p_doc->'days','[]'::jsonb)) d),'[]'::jsonb)
  else '[]'::jsonb end
$function$
;
