-- public.v2_practice_scopes(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f7eecfa9155d46bf689cc7153b101901
CREATE OR REPLACE FUNCTION public.v2_practice_scopes(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception '%', v2.not_my_school_ar(); end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'key',s.key,'label',s.label_ar,'ord',s.ord,
      'owned',(s.school_id is not null)) order by s.ord, s.key),'[]'::jsonb)
  into r from v2.practice_scopes s
  where s.active and (s.school_id is null or s.school_id = p_school);
  return r;
end $function$
;
