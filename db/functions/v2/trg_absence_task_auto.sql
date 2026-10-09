-- v2.trg_absence_task_auto()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5a9cd22ed7fa6f672bf5b06467d64d48
CREATE OR REPLACE FUNCTION v2.trg_absence_task_auto()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.absence_task_auto(new.id);
  return null;
end $function$
;
