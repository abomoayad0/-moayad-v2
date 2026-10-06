-- v2.g_open_case_on_refer()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4dd24f99f999891449468f5611deeaed
CREATE OR REPLACE FUNCTION v2.g_open_case_on_refer()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  if new.kind = 'counselor' then
    perform v2.fn_open_counsel_case(new.record_id);
  end if;
  return new;
end $function$
;
