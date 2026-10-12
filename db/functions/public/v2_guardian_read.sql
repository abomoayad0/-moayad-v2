-- public.v2_guardian_read(p_event uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 55477764f91bdef4436c7a666fc4305e
CREATE OR REPLACE FUNCTION public.v2_guardian_read(p_event uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  -- الشرطُ نفسُه الذي كان في الأصل — فإن لم يُوجد تسليمٌ له، لا شيء ولا خطأ
  if exists (select 1 from v2.event_deliveries d
              where d.event_id = p_event and d.channel = 'guardian_portal'
                and d.to_guardian in (select g.id from v2.guardians g
                                       where g.user_id = auth.uid()
                                         and coalesce(g.portal_active,true))) then
    perform public.v2_seen(p_event);
  end if;
end $function$
;
