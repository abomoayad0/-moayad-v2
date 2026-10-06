-- public.v2_delegate_add(p_school uuid, p_post text, p_to uuid, p_starts date, p_ends date, p_reason text, p_letter text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 203e54d027b83b0bc9fcc0bee7084040
CREATE OR REPLACE FUNCTION public.v2_delegate_add(p_school uuid, p_post text, p_to uuid, p_starts date, p_ends date, p_reason text, p_letter text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare nid uuid; owner_p uuid; nm text;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy'],'الإنابةَ في صفة');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if not exists (select 1 from v2.posts where key=p_post) then
    raise exception 'وظيفةٌ غيرُ معروفة'; end if;
  if not exists (select 1 from v2.assignments a
        where a.person_id=p_to and a.school_id=p_school and a.ended_on is null) then
    raise exception 'المنابُ ليس من منسوبي مدرستك'; end if;
  if btrim(coalesce(p_reason,''))='' then
    raise exception 'لا إنابةَ بلا سببٍ مكتوب — غيابٌ أو إجازةٌ أو انتدابٌ أو خلوُّ الوظيفة'; end if;
  if p_ends is not null and p_ends < coalesce(p_starts,current_date) then
    raise exception 'نهايةُ الإنابة قبل بدايتها'; end if;

  select a.person_id into owner_p from v2.assignments a
   where a.post_key=p_post and a.school_id=p_school and a.ended_on is null limit 1;
  if owner_p = p_to then
    raise exception 'هذي صفتُه أصالةً — ولا يُناب عن نفسه'; end if;

  if exists (select 1 from v2.delegations d
              where d.school_id=p_school and d.post_key=p_post and d.to_person=p_to
                and d.revoked_at is null
                and (d.ends_on is null or d.ends_on >= current_date)) then
    raise exception 'له إنابةٌ قائمةٌ في هذي الصفة'; end if;

  insert into v2.delegations(school_id,post_key,from_person,to_person,
      starts_on,ends_on,reason,letter_no,issued_by)
  values (p_school,p_post,owner_p,p_to,coalesce(p_starts,current_date),p_ends,
      btrim(p_reason),nullif(btrim(coalesce(p_letter,'')),''),v2.current_person())
  returning id into nid;

  select v2.fn_display_name(full_name) into nm from v2.people where id=p_to;
  return jsonb_build_object('ok',true,'delegation',nid,'to',nm,
    'note','أُنيب '||nm||' في «'||v2.role_ar(p_post)||'»'||
      case when p_ends is null then ' حتى تُلغى' else ' حتى '||p_ends end);
end $function$
;
