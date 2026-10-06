-- public.v2_structure_board(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2636bdbb96ae024b8dc7ecbdfa95b5e2
CREATE OR REPLACE FUNCTION public.v2_structure_board(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb; v_code text;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select s.structure_code into v_code from v2.schools s where s.id=p_school;
  select jsonb_build_object(
    'current', (select jsonb_build_object('code',st.code,'label',st.label_ar,
                  'deputies',st.deputy_count,'source',st.source_page)
                from v2.structures st where st.code = v_code),
    'all', (select coalesce(jsonb_agg(jsonb_build_object(
              'code',st.code,'label',st.label_ar,'deputies',st.deputy_count,
              'source',st.source_page,
              'posts',(select count(*) from v2.structure_posts sp where sp.structure_code=st.code),
              -- 🔑 كم تكليفًا يبقى خارجَه إن اختير
              'orphans',(select count(distinct a.post_key) from v2.assignments a
                          where a.school_id=p_school and a.ended_on is null
                            and not exists (select 1 from v2.structure_posts sp
                                 where sp.structure_code=st.code and sp.post_key=a.post_key)))
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
            where sp.structure_code = v_code),
    'outside', (select coalesce(jsonb_agg(distinct jsonb_build_object(
              'post',a.post_key,'label',v2.role_ar(a.post_key))),'[]'::jsonb)
            from v2.assignments a
            where a.school_id=p_school and a.ended_on is null
              and (v_code is null or not exists (select 1 from v2.structure_posts sp
                   where sp.structure_code=v_code and sp.post_key=a.post_key))),
    'note','الهيكلُ نصُّ الدليل التنظيميّ — تختار مدرستُك واحدًا منه ولا تخترع'
  ) into r;
  return r;
end $function$
;
