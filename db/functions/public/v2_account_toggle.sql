-- public.v2_account_toggle(p_person uuid, p_active boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 199b1d1f18ffb449778ccb42ebc3d024
CREATE OR REPLACE FUNCTION public.v2_account_toggle(p_person uuid, p_active boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare me uuid; mine text; theirs text; rank_me int; rank_them int;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy'],'إيقافَ حسابٍ أو تفعيلَه');
  me := v2.current_person();
  if p_person = me then raise exception 'لا توقف حسابَك بنفسك'; end if;
  if not exists (select 1 from v2.assignments a
                  where a.person_id=p_person and a.ended_on is null
                    and v2.my_school(a.school_id)) then
    raise exception 'هذا المنسوب ليس من منسوبي مدرستك'; end if;

  mine   := v2.my_grant();
  select u.role into theirs from v2.app_users u where u.person_id=p_person;
  if theirs is null then raise exception 'لا حسابَ لهذا المنسوب'; end if;

  rank_me    := case mine   when 'owner' then 4 when 'admin' then 3
                            when 'operator' then 2 else 1 end;
  rank_them  := case theirs when 'owner' then 4 when 'admin' then 3
                            when 'operator' then 2 else 1 end;
  -- 🔑 ولا يُمسّ من هو مثلُك أو أعلى
  if rank_them >= rank_me then
    raise exception 'لا تملك إيقافَ حسابٍ صلاحيّتُه (%) ومثلُها أو أعلى من صلاحيّتك', theirs; end if;

  update v2.app_users set is_active=coalesce(p_active,false) where person_id=p_person;
  return jsonb_build_object('ok',true,'active',coalesce(p_active,false));
end $function$
;
