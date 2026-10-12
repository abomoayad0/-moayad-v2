-- public.v2_mail_inbox(p_school uuid, p_status text, p_days integer)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4658c3f2f4935a0d5e76ec67ae83ad02
CREATE OR REPLACE FUNCTION public.v2_mail_inbox(p_school uuid, p_status text DEFAULT NULL::text, p_days integer DEFAULT 90)
 RETURNS TABLE(mail_id uuid, serial_no integer, serial_ar text, ref_no text, subject_ar text, from_entity text, received_h text, received_g date, secrecy text, status text, status_ar text, items_n integer, items_ar text, open_items integer, open_items_ar text, late_items integer, late_items_ar text, attachments_n integer, attachments_ar text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_may boolean;
begin
  perform v2.assert_my_school(p_school,'قراءة سجل الوارد');
  perform v2.assert_role(array['principal','deputy','deputy_students','deputy_school',
      'deputy_school_students','admin_assistant','admin_assistant_students','counselor'],
      'قراءةَ سجلّ الوارد المدرسيّ');
  v_may := v2.may_read_secret_mail();
  return query
  with rows as (
   select m.id as mail_id, m.serial_no, m.ref_no,
     case when m.secrecy = 'عادي' or v_may then m.subject_ar
          else 'خطابٌ '||m.secrecy||' — لا يُعرض عنوانُه هنا' end as subject_ar,
     m.from_entity,
     m.received_on_h||' هـ' as received_h, m.received_on_g, m.secrecy, m.status,
     case m.status when 'new' then 'جديد' when 'directed' then 'موجَّه'
          when 'in_progress' then 'قيد التنفيذ' when 'closed' then 'مغلق' else m.status end as status_ar,
     (select count(*)::int from v2.mail_items i where i.mail_id=m.id) as items_n,
     (select count(*)::int from v2.mail_items i join v2.mail_followups f on f.item_id=i.id
       where i.mail_id=m.id and f.status<>'done') as open_items,
     (select count(*)::int from v2.mail_items i join v2.mail_followups f on f.item_id=i.id
       where i.mail_id=m.id and f.status<>'done' and f.due_on < current_date) as late_items,
     (select count(*)::int from v2.mail_attachments a where a.mail_id=m.id) as attachments_n
   from v2.incoming_mail m
   where m.school_id=p_school and (p_status is null or m.status=p_status)
     and m.received_on_g > current_date - p_days)
  select r.mail_id, r.serial_no, v2.serial_ar(r.serial_no,'in'), r.ref_no, r.subject_ar,
     r.from_entity, r.received_h, r.received_on_g, r.secrecy, r.status, r.status_ar,
     r.items_n, v2.ar_count0(r.items_n,'بلا بنود','بندٌ واحد','بندان','بنود','بندًا'),
     r.open_items, v2.ar_count0(r.open_items,'لا بندَ مفتوح','بندٌ مفتوحٌ واحد','بندان مفتوحان','بنودٍ مفتوحة','بندًا مفتوحًا'),
     r.late_items, v2.ar_count0(r.late_items,'ولا متأخّر','ومتأخّرٌ واحد','ومتأخّران','ومتأخّرة','ومتأخّرًا'),
     r.attachments_n, v2.ar_count0(r.attachments_n,'بلا مرفقات','مرفقٌ واحد','مرفقان','مرفقات','مرفقًا')
   from rows r
   order by r.received_on_g desc, r.serial_no desc;
end $function$
;
