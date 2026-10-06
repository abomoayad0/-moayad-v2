-- public.v2_structure_board(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c516793c1167a803112ea5a49d6671be
CREATE OR REPLACE FUNCTION public.v2_structure_board(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb; code text;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select structure_code into code from v2.schools where id=p_school;
  select jsonb_build_object(
    'current', (select jsonb_build_object('code',st.code,'label',st.label_ar,
                  'deputies',st.deputy_count,'source',st.source_page)
                from v2.structures st where st.code=code),
    'all', (select coalesce(jsonb_agg(jsonb_build_object(
              'code',st.code,'label',st.label_ar,'deputies',st.deputy_count,
              'source',st.source_page,
              'posts',(select count(*) from v2.structure_posts sp where sp.structure_code=st.code))
              order by st.code),'[]'::jsonb) from v2.structures st),
    'posts', (select coalesce(jsonb_agg(jsonb_build_object(
              'post',sp.post_key,'label',p.label_ar,
              'parent',sp.parent_post_key,
              'parent_ar',(select label_ar from v2.posts where key=sp.parent_post_key),
              'filled',(select count(*) from v2.assignments a
                         where a.post_key=sp.post_key and a.school_id=p_school
                           and a.ended_on is null))
              order by p.label_ar),'[]'::jsonb)
            from v2.structure_posts sp join v2.posts p on p.key=sp.post_key
            where sp.structure_code=code),
    'note','الهيكلُ نصُّ الدليل التنظيميّ — تختار مدرستُك واحدًا منه ولا تخترع'
  ) into r;
  return r;
end $function$
;
