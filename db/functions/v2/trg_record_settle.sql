-- v2.trg_record_settle()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 797d398b535bc884169d31bebe3921af
CREATE OR REPLACE FUNCTION v2.trg_record_settle()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.fn_record_settle(coalesce(new.record_id, old.record_id));
  return null;
end
$function$
;
