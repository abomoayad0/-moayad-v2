-- v2.fn_log_error(p_message text, p_fn text, p_screen text, p_action text, p_params jsonb, p_sqlstate text, p_detail text, p_hint text, p_context text, p_source text, p_kind text, p_ua text, p_url text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d724dfe18a7bc84160ad33de1513a220
CREATE OR REPLACE FUNCTION v2.fn_log_error(p_message text, p_fn text DEFAULT NULL::text, p_screen text DEFAULT NULL::text, p_action text DEFAULT NULL::text, p_params jsonb DEFAULT NULL::jsonb, p_sqlstate text DEFAULT NULL::text, p_detail text DEFAULT NULL::text, p_hint text DEFAULT NULL::text, p_context text DEFAULT NULL::text, p_source text DEFAULT 'bridge'::text, p_kind text DEFAULT 'error'::text, p_ua text DEFAULT NULL::text, p_url text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_id uuid; sc uuid;
begin
  select school_id into sc from v2.session_role where user_id = auth.uid();
  insert into v2.error_log (user_id, person_ar, role_ar, school_id, school_ar,
    source, screen, action, fn_name, params, sqlstate, message, detail, hint, context, ua, url, kind)
  values (auth.uid(),
    (select v2.fn_display_name(pe.full_name) from v2.app_users u join v2.people pe on pe.id=u.person_id where u.id=auth.uid()),
    v2.role_ar(v2.my_role()), sc, (select name_ar from v2.schools where id=sc),
    p_source, p_screen, p_action, p_fn, p_params, p_sqlstate, p_message, p_detail, p_hint, p_context,
    p_ua, p_url, p_kind)
  returning id into v_id;
  return v_id;
end $function$
;
