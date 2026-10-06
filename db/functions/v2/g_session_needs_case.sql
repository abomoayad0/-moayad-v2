-- v2.g_session_needs_case()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f320e32b75659097335425c2089c7daf
CREATE OR REPLACE FUNCTION v2.g_session_needs_case()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
declare c record;
begin
  select * into c from v2.counsel_cases where id = new.case_id;
  if c.written_at is null then
    raise exception 'لا تُفتح جلسةٌ قبل أن تُكتب دراسةُ الحالة — فالجلسةُ تدخّلٌ والتدخّلُ بعد الدراسة';
  end if;
  return new;
end $function$
;
