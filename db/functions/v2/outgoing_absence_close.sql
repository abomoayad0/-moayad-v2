-- v2.outgoing_absence_close(p_mail uuid, p_event text, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 87b14b167f0220cf34858467b4e1f0ae
CREATE OR REPLACE FUNCTION v2.outgoing_absence_close(p_mail uuid, p_event text, p_note text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare n integer := 0;
begin
  update v2.absence_tasks ab
     set status='done', done_at=now(), done_by=v2.current_person(),
         ev_on=current_date, ev_ref=p_note, ev_text=p_note
   where ab.status <> 'done'
     and ab.id in (select lt.source_id from v2.outgoing_links lt
                    where lt.mail_id = p_mail and lt.source='absence' and lt.on_event = p_event);
  get diagnostics n = row_count;
  return n;
end $function$
;
