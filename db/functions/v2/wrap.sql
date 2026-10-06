-- v2.wrap(p_fn text, p_sql text, p_params jsonb)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 03b1a50a6ee7cf2c630264766c0299be
CREATE OR REPLACE FUNCTION v2.wrap(p_fn text, p_sql text, p_params jsonb DEFAULT NULL::jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  execute p_sql;
exception when others then
  perform v2.fn_log_error(sqlerrm, p_fn, null, null, p_params,
    sqlstate, pg_exception_detail, pg_exception_hint, pg_exception_context, 'bridge',
    case when sqlstate='P0001' then 'guard' else 'error' end);
  raise;
end $function$
;
