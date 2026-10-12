-- v2.swap_notify(p_school uuid, p_title text, p_body text, p_to uuid, p_on date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8e56ca1f3a7aa90e76998552ec9dadfe
CREATE OR REPLACE FUNCTION v2.swap_notify(p_school uuid, p_title text, p_body text, p_to uuid, p_on date)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_ev uuid;
begin
  if p_to is null then return; end if;
  insert into v2.events(school_id, kind, on_date, title_ar, body_ar, visible_to, ref_table)
  values (p_school, 'other', p_on, p_title, p_body, 'staff', 'period_swaps')
  returning id into v_ev;
  insert into v2.event_deliveries(event_id, channel, to_person, status, sent_at)
  values (v_ev, 'staff_inbox', p_to, 'sent', now());
end $function$
;
