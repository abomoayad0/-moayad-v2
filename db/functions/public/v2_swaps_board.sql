-- public.v2_swaps_board(p_school uuid, p_days integer)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4fbede996383a0a5ea31962a7e4d1396
CREATE OR REPLACE FUNCTION public.v2_swaps_board(p_school uuid, p_days integer DEFAULT 30)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_me uuid := v2.current_person(); r jsonb; n_me int; n_admin int;
begin
  perform v2.assert_my_school(p_school,'قراءةَ لوحة التبديلات');
  select coalesce(jsonb_agg(jsonb_build_object(
      'swap', w.id, 'on_h', v2.fn_to_hijri(w.on_date)||' هـ', 'on_date', w.on_date,
      'status', w.status,
      'state_ar', case w.status
        when 'pending'    then '🟠 ينتظر زميلَك'
        when 'partner_ok' then '🔵 ينتظر اعتمادَ الوكيل'
        when 'partner_no' then '⚪ اعتذر زميلُك'
        when 'admin_no'   then '🔴 لم تعتمده الإدارة'
        when 'done'       then '✅ تمّ التبديل'
        when 'cancelled'  then '⚪ أُلغي'
        else '⚪ سقط بمضيّ يومه' end,
      'requester_ar', v2.fn_display_name(p1.full_name),
      'partner_ar',   v2.fn_display_name(p2.full_name),
      'req_period', t1.period_no, 'partner_period', t2.period_no,
      'req_section',  coalesce(c1.label_ar,'—'), 'partner_section', coalesce(c2.label_ar,'—'),
      'reason', w.reason_ar, 'partner_note', w.partner_note, 'admin_note', w.admin_note,
      'mine', case when w.requester=v_me then 'requester'
                   when w.partner=v_me then 'partner' else 'other' end)
      order by w.on_date desc, w.created_at desc),'[]'::jsonb) into r
    from v2.period_swaps w
    join v2.people p1 on p1.id=w.requester
    join v2.people p2 on p2.id=w.partner
    join v2.timetable t1 on t1.id=w.req_slot
    join v2.timetable t2 on t2.id=w.partner_slot
    left join v2.class_sections c1 on c1.id=t1.section_id
    left join v2.class_sections c2 on c2.id=t2.section_id
   where w.school_id=p_school and w.on_date >= current_date - coalesce(p_days,30);

  select count(*) filter (where (x->>'mine')='partner' and (x->>'status')='pending'),
         count(*) filter (where (x->>'status')='partner_ok')
    into n_me, n_admin from jsonb_array_elements(r) x;

  return jsonb_build_object('rows',r,'count',jsonb_array_length(r),
    'waiting_me',n_me,'waiting_admin',n_admin,
    'summary_ar', case when jsonb_array_length(r)=0 then 'لا طلباتِ تبديل'
      else v2.ar_count(jsonb_array_length(r),'طلبٌ واحد','طلبان','طلباتٍ','طلبًا')
           || case when n_me>0 then ' · 🟠 ينتظر جوابَك '||n_me::text else '' end
           || case when n_admin>0 then ' · 🔵 ينتظر الاعتماد '||n_admin::text else '' end end,
    'note_ar','التبديلُ ليومٍ واحدٍ ولا يمسّ الجدولَ المعتمد. '
      ||'ويبدّل الوقتَ لا المادّة — فتُدرّس مادّتَك أنت في ذلك الفصل. '
      ||'وسلّمُه: تطلب ← يوافق زميلُك ← يعتمد الوكيلُ للشؤون التعليميّة (س-٨-ا-١ ص٢٠١).');
end $function$
;
