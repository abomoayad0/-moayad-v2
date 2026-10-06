-- v2.g_report_needs_sessions()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8bd3a901388e33fe61083bc9b9c3f030
CREATE OR REPLACE FUNCTION v2.g_report_needs_sessions()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
declare c record; n int;
begin
  select * into c from v2.counsel_cases where id = new.case_id;
  if c.written_at is null then
    raise exception 'لا يُرفع تقريرٌ قبل أن تُكتب دراسةُ الحالة'; end if;
  select count(*) into n from v2.counsel_sessions where case_id = new.case_id;
  if n = 0 then
    raise exception 'لا يُرفع تقريرٌ بلا جلسةِ متابعةٍ واحدةٍ على الأقلّ'; end if;
  return new;
end $function$
;
