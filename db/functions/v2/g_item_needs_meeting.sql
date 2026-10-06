-- v2.g_item_needs_meeting()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b3a7e8b12e04943076add5c52cff2506
CREATE OR REPLACE FUNCTION v2.g_item_needs_meeting()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
declare st text;
begin
  select status into st from v2.committee_meetings where id = new.meeting_id;
  if new.outcome <> 'قيد النظر' and st = 'مدعوّ إليه' then
    raise exception 'لا يُقرَّر بندٌ قبل انعقاد الاجتماع';
  end if;
  return new;
end $function$
;
