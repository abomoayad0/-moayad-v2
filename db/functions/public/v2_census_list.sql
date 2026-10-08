-- public.v2_census_list(p_school uuid, p_all boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 72ff7e24f27e43644d2490eac1c31993
CREATE OR REPLACE FUNCTION public.v2_census_list(p_school uuid, p_all boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select jsonb_build_object(
    'negative', (select coalesce(jsonb_agg(jsonb_build_object(
        'id',c.id,'icon',c.icon,'text',c.text_ar,'hint',c.hint_ar,'ord',c.ord,
        'active',c.active,'mine',(c.school_id is not null)) order by c.ord),'[]'::jsonb)
      from v2.census_items c where c.polarity='negative'
        and (coalesce(p_all,false) or c.active)
        and (c.school_id is null or c.school_id=p_school)),
    'positive', (select coalesce(jsonb_agg(jsonb_build_object(
        'id',c.id,'icon',c.icon,'text',c.text_ar,'hint',c.hint_ar,'ord',c.ord,
        'active',c.active,'mine',(c.school_id is not null)) order by c.ord),'[]'::jsonb)
      from v2.census_items c where c.polarity='positive'
        and (coalesce(p_all,false) or c.active)
        and (c.school_id is null or c.school_id=p_school))
  ) into r;
  return r;
end $function$
;
