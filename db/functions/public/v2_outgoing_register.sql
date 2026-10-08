-- public.v2_outgoing_register(p_school uuid, p_days integer, p_status text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 36f3212fe20c932fe3d42fd4e99bd65e
CREATE OR REPLACE FUNCTION public.v2_outgoing_register(p_school uuid DEFAULT NULL::uuid, p_days integer DEFAULT 365, p_status text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; rows jsonb; n integer;
begin
  perform v2.assert_role(array['principal','deputy','deputy_students',
      'admin_assistant','admin_assistant_students'],'سجلّ الصادر');
  sc := coalesce(p_school, v2.acting_school());
  perform v2.assert_my_school(sc,'سجلّ الصادر');

  select coalesce(jsonb_agg(jsonb_build_object(
           'mail', m.id,
           'serial', m.serial_no,
           'serial_ar', case when m.serial_no is null then 'بلا رقم' else v2.ar_num(m.serial_no) end,
           'subject', case when m.secrecy = 'عادي' then m.subject_ar
                           else 'خطابٌ '||m.secrecy||' — لا يُعرض عنوانُه هنا' end,
           'to_entity', m.to_entity,
           'kind', m.kind,
           'secrecy', m.secrecy,
           'status', m.status,
           'issued_ar', case when m.issued_on_g is null then null
                             else coalesce(m.issued_on_h, v2.fn_to_hijri(m.issued_on_g))||' هـ' end,
           'sent_on', m.sent_on,
           'needs_reply', m.needs_reply,
           'reply_on', m.reply_on,
           'overdue_days', case when m.needs_reply and m.reply_on is null
                                     and m.reply_due_on is not null and m.reply_due_on < current_date
                                then current_date - m.reply_due_on else null end)
         order by m.serial_no desc nulls first, m.created_at desc), '[]'::jsonb)
    into rows
    from v2.outgoing_mail m
   where m.school_id = sc
     and (p_status is null or m.status = p_status)
     and m.created_at >= now() - make_interval(days => greatest(coalesce(p_days,365),1));

  n := jsonb_array_length(rows);
  return jsonb_build_object(
    'rows', rows,
    'count', n,
    'summary_ar', case when n = 0
      then 'لا صادرَ في هذي المدّة'
      else 'في السجلّ '||v2.ar_count(n,'خطابٌ واحد','خطابان','خطابات','خطابًا') end,
    'note_ar', 'الخطابُ السرّيُّ يظهر في السجلّ برقمه وجهته ولا يظهر عنوانُه — '||
               'ويُقرأ كاملًا من المدير والوكيل وحدَهما');
end $function$
;
