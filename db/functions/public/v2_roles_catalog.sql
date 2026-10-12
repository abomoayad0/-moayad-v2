-- public.v2_roles_catalog(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 908cca3f828b2324100df81648f03d69
CREATE OR REPLACE FUNCTION public.v2_roles_catalog(p_school uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid := coalesce(p_school, v2.acting_school());
begin
  return coalesce((
    select jsonb_agg(jsonb_build_object(
        'code',r.code,'title_ar',r.title_ar,'max_holders',r.max_holders,
        'ord',r.ord,'active',r.active,'note_ar',r.note_ar,
        'own', r.school_id is not null) order by r.ord, r.code)
    from v2.class_roles r
    where r.school_id is null or r.school_id = sc), '[]'::jsonb);
end $function$
;
