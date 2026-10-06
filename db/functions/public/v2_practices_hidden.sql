-- public.v2_practices_hidden(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 695ac38f9f57ebd120fb193c726a8141
CREATE OR REPLACE FUNCTION public.v2_practices_hidden(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'code',p.code,'title',coalesce(o.title_ar,p.title_ar),
      'scope',coalesce(o.scope,p.scope),
      'scope_ar',(select s.label_ar from v2.practice_scopes s
                   where s.key=coalesce(o.scope,p.scope) limit 1),
      'polarity',coalesce(o.polarity,p.polarity),
      'mine',(p.school_id is not null),
      'hidden_at',o.set_at) order by p.scope, p.code),'[]'::jsonb)
  into r
  from v2.practice_overrides o
  join v2.class_practices p on p.code=o.code
  where o.school_id=p_school and o.hidden;
  return r;
end $function$
;
