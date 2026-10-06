-- public.v2_my_acting(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 36757e215a11ef75e6be7b6454c17e3d
CREATE OR REPLACE FUNCTION public.v2_my_acting(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'post',x.post_key,'post_ar',v2.role_ar(x.post_key),
      'by_delegation',x.by_delegation,
      'how', case when x.by_delegation then 'إنابة' else 'أصالة' end,
      'until',(select d.ends_on from v2.delegations d where d.id=x.delegation_id),
      'reason',(select d.reason from v2.delegations d where d.id=x.delegation_id))
      order by x.by_delegation, x.post_key),'[]'::jsonb)
  into r from v2.acting_posts(p_school) x;
  return r;
end $function$
;
