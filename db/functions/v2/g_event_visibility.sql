-- v2.g_event_visibility()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 818375a7de50795d2e4a41fe03dd8445
CREATE OR REPLACE FUNCTION v2.g_event_visibility()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  if new.ref_table in ('case_study','counselor_sessions','case_report')
     or new.kind in ('case_study','counselor_session') then
    new.visible_to := 'counselor_only';
  end if;
  if new.visible_to is null then new.visible_to := 'staff'; end if;
  return new;
end $function$
;
