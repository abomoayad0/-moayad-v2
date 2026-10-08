-- v2.trg_police_after_guardian()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 25b6bee7e51c64bd85664d0f5c5d18cf
CREATE OR REPLACE FUNCTION v2.trg_police_after_guardian()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
begin
  if new.kind = 'police'
     and new.status = 'done'
     and coalesce(old.status,'') <> 'done'
     and exists (select 1 from v2.behavior_tasks x
                  where x.record_id = new.record_id
                    and x.kind = 'notify_guardian'
                    and x.status = 'open')
  then
    raise exception 'نصُّ الدليل: «تبليغُ الجهات الأمنيّة المختصّة فور وقوع المشكلة، بعد إشعار وليّ الأمر» — فأتمِم بندَ إشعار وليّ الأمر أوّلًا، أو أسقِطه بسببٍ مكتوبٍ إن لم يُستجَب له';
  end if;
  return new;
end
$function$
;
