-- v2.trg_day_closed_guard()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 70a2f1c63b2eeb4acdc8aa45b2aad99f
CREATE OR REPLACE FUNCTION v2.trg_day_closed_guard()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare c record;
begin
  select * into c from v2.day_closures where school_id=new.school_id and on_date=new.on_date;
  if c.id is not null and c.reopened_at is null then
    raise exception 'يوم % مقفَل — لا يُعدَّل سجله إلا بإعادة فتح موثّقة بسبب مكتوب', new.on_date;
  end if;
  return new;
end $function$
;
