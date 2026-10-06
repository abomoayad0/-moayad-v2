-- public.v2_mail_my_tasks(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c6295040815896fb98ac730041dd9bd1
CREATE OR REPLACE FUNCTION public.v2_mail_my_tasks(p_school uuid)
 RETURNS TABLE(followup_id uuid, item_id uuid, serial_no integer, subject_ar text, text_ar text, due_on date, due_h text, is_late boolean, status text, reminders_n smallint)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_school(p_school,'قراءة مهامّ الوارد');
  return query
   select f.id, i.id, m.serial_no, m.subject_ar, i.text_ar, f.due_on,
     case when f.due_on is null then null else v2.fn_to_hijri(f.due_on)||' هـ' end,
     (f.due_on is not null and f.due_on < current_date and f.status<>'done'),
     f.status, f.reminders_n
   from v2.mail_followups f
   join v2.mail_items i on i.id=f.item_id
   join v2.incoming_mail m on m.id=i.mail_id
   where m.school_id=p_school and f.status<>'done'
     and (f.person_id = v2.current_person() or f.role_ar = v2.role_ar(v2.my_role()))
   order by f.due_on nulls last;
end $function$
;
