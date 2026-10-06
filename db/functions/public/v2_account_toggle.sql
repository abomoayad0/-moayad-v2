-- public.v2_account_toggle(p_person uuid, p_active boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a9e514c0fba81369bbee3ba291bc7d3a
CREATE OR REPLACE FUNCTION public.v2_account_toggle(p_person uuid, p_active boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare me uuid;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy'],'إيقافَ حسابٍ أو تفعيلَه');
  me := v2.current_person();
  if p_person = me then raise exception 'لا توقف حسابَك بنفسك'; end if;
  if not exists (select 1 from v2.assignments a
                  where a.person_id=p_person and a.ended_on is null
                    and v2.my_school(a.school_id)) then
    raise exception 'هذا المنسوب ليس من منسوبي مدرستك'; end if;
  -- 🔒 ولا تُرفع صلاحيّةٌ من هنا — التفعيلُ والإيقافُ فقط
  update v2.app_users set is_active=coalesce(p_active,false) where person_id=p_person;
  if not found then raise exception 'لا حسابَ لهذا المنسوب'; end if;
  return jsonb_build_object('ok',true,'active',coalesce(p_active,false));
end $function$
;
