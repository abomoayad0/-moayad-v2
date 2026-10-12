-- public.v2_mail_my_tasks(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9801afbf3528b8da4469b7328758e1f3
CREATE OR REPLACE FUNCTION public.v2_mail_my_tasks(p_school uuid)
 RETURNS TABLE(followup_id uuid, item_id uuid, mail_id uuid, serial_no integer, subject_ar text, text_ar text, due_on date, due_h text, is_late boolean, late_ar text, status text, reminders_n smallint, reminders_ar text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare me uuid; v_may boolean; v_days int;
begin
  me := v2.current_person();
  if me is null then raise exception 'لا بدّ من تسجيل الدخول'; end if;
  perform v2.assert_my_school(p_school, 'متابعاتي في الوارد');
  v_may  := v2.may_read_secret_mail();
  v_days := (v2.rule_n(p_school,'mail_followup_done_days'))::int;

  return query
  select f.id, f.item_id, m.id, m.serial_no,
         case when m.secrecy = 'عادي' or v_may then m.subject_ar
              else 'خطابٌ '||m.secrecy||' — لا يُعرض عنوانُه هنا' end,
         i.text_ar,
         f.due_on,
         case when f.due_on is null then 'بلا موعدٍ محدَّد'
              else v2.fn_to_hijri(f.due_on)||' هـ' end,
         (f.due_on is not null and f.due_on < current_date
            and f.status not in ('done','closed','not_required')),
         case
           when f.status in ('done','closed','not_required') then null
           when f.due_on is null then null
           when f.due_on < current_date then 'تأخّر '||
                v2.ar_count(current_date - f.due_on,'يومًا واحدًا','يومين','أيّام','يومًا')
           when f.due_on = current_date then 'موعدُه اليومَ'
           else 'بقي له '||
                v2.ar_count(f.due_on - current_date,'يومٌ واحد','يومان','أيّام','يومًا') end,
         f.status,
         f.reminders_n,
         case when coalesce(f.reminders_n,0) = 0 then 'لم يُذكَّر به'
              else 'ذُكِّر به '||
                   v2.ar_count(f.reminders_n,'مرّةً واحدة','مرّتين','مرّات','مرّة') end
    from v2.mail_followups f
    join v2.mail_items i     on i.id = f.item_id
    join v2.incoming_mail m  on m.id = i.mail_id
   where f.person_id = me
     and m.school_id = p_school
     and (f.status not in ('done','closed','not_required')
          or coalesce(f.done_at::date, f.created_at::date) >= current_date - v_days)
   order by (f.status not in ('done','closed','not_required')) desc,
            f.due_on nulls last, m.serial_no;
end $function$
;
