-- public.v2_census_list(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c10c95a5580542c5a950ac9b47dff44b
CREATE OR REPLACE FUNCTION public.v2_census_list(p_school uuid)
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
        'mine',(c.school_id is not null)) order by c.ord),'[]'::jsonb)
      from v2.census_items c where c.active and c.polarity='negative'
        and (c.school_id is null or c.school_id=p_school)),
    'positive', (select coalesce(jsonb_agg(jsonb_build_object(
        'id',c.id,'icon',c.icon,'text',c.text_ar,'hint',c.hint_ar,'ord',c.ord,
        'mine',(c.school_id is not null)) order by c.ord),'[]'::jsonb)
      from v2.census_items c where c.active and c.polarity='positive'
        and (c.school_id is null or c.school_id=p_school))
  ) into r;
  return r;
end $function$
;
