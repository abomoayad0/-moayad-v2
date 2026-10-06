-- public.v2_structure_set(p_school uuid, p_code text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 71e800d56e6901f36eba261851dcc9f5
CREATE OR REPLACE FUNCTION public.v2_structure_set(p_school uuid, p_code text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare n int; orphan text;
begin
  perform v2.assert_role(array['principal'],'تغييرَ الهيكل التنظيميّ');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if not exists (select 1 from v2.structures where code=p_code) then
    raise exception 'هيكلٌ غيرُ معروفٍ في الدليل التنظيميّ'; end if;

  -- 🔒 ولا يُترك مكلَّفٌ خارجَ الهيكل الجديد
  select string_agg(distinct v2.role_ar(a.post_key),' · ') into orphan
    from v2.assignments a
   where a.school_id=p_school and a.ended_on is null
     and not exists (select 1 from v2.structure_posts sp
                      where sp.structure_code=p_code and sp.post_key=a.post_key);
  if orphan is not null then
    raise exception 'في مدرستك تكاليفُ لا موضعَ لها في هذا الهيكل: % — أنهِها أوّلًا', orphan;
  end if;

  update v2.schools set structure_code=p_code where id=p_school;
  select count(*) into n from v2.structure_posts where structure_code=p_code;
  return jsonb_build_object('ok',true,'code',p_code,'posts',n);
end $function$
;
