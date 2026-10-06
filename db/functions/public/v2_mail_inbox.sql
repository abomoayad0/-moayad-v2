-- public.v2_mail_inbox(p_school uuid, p_status text, p_days integer)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3e0b5905d69a2b67712610c6819fd746
CREATE OR REPLACE FUNCTION public.v2_mail_inbox(p_school uuid, p_status text DEFAULT NULL::text, p_days integer DEFAULT 90)
 RETURNS TABLE(mail_id uuid, serial_no integer, ref_no text, subject_ar text, from_entity text, received_h text, received_g date, secrecy text, status text, status_ar text, items_n integer, open_items integer, late_items integer, attachments_n integer)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_school(p_school,'قراءة سجل الوارد');
  return query
   select m.id, m.serial_no, m.ref_no, m.subject_ar, m.from_entity,
     m.received_on_h||' هـ', m.received_on_g, m.secrecy, m.status,
     case m.status when 'new' then 'جديد' when 'directed' then 'موجَّه'
          when 'in_progress' then 'قيد التنفيذ' when 'closed' then 'مغلق' else m.status end,
     (select count(*)::int from v2.mail_items i where i.mail_id=m.id),
     (select count(*)::int from v2.mail_items i join v2.mail_followups f on f.item_id=i.id
       where i.mail_id=m.id and f.status<>'done'),
     (select count(*)::int from v2.mail_items i join v2.mail_followups f on f.item_id=i.id
       where i.mail_id=m.id and f.status<>'done' and f.due_on < current_date),
     (select count(*)::int from v2.mail_attachments a where a.mail_id=m.id)
   from v2.incoming_mail m
   where m.school_id=p_school and (p_status is null or m.status=p_status)
     and m.received_on_g > current_date - p_days
   order by m.received_on_g desc, m.serial_no desc;
end $function$
;
