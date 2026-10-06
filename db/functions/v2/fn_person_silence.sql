-- v2.fn_person_silence()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5d52b199c8c8a3da4ce1f668e94421c5
CREATE OR REPLACE FUNCTION v2.fn_person_silence()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
begin
  if new.status in ('deceased','left') then
    new.contactable := false;
    if new.status_changed_on is null then new.status_changed_on := current_date; end if;
  end if;
  return new;
end $function$
;
