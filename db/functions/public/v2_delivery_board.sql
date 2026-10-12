-- public.v2_delivery_board(p_school uuid, p_days integer)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d4d99e2672c8db89de444cc5aa67f8b8
CREATE OR REPLACE FUNCTION public.v2_delivery_board(p_school uuid, p_days integer DEFAULT 30)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb; v_sent int; v_read int; v_fail int; v_wait int;
begin
  perform v2.assert_my_school(p_school,'لوحةَ إثبات الوصول');
  perform v2.assert_role(array['principal','deputy','deputy_students','deputy_school',
      'deputy_school_students','admin_assistant','admin_assistant_students','counselor'],
      'لوحةَ إثبات الوصول');

  select count(*) filter (where d.status <> 'cancelled'),
         count(*) filter (where d.read_at is not null),
         count(*) filter (where d.status = 'failed'),
         count(*) filter (where d.read_at is null and d.status in ('sent','delivered','queued'))
    into v_sent, v_read, v_fail, v_wait
    from v2.event_deliveries d join v2.events e on e.id=d.event_id
   where e.school_id = p_school and d.created_at > now() - make_interval(days => greatest(coalesce(p_days,30),1));

  select coalesce(jsonb_agg(x),'[]'::jsonb) into r from (
    select jsonb_build_object(
      'event', e.id, 'kind', e.kind, 'title', e.title_ar,
      'student', (select v2.fn_display_name(s.full_name) from v2.students s where s.id=e.student_id),
      'to_ar', case d.channel when 'student_portal' then 'صفحةُ الطالب'
                              when 'guardian_portal' then 'صفحةُ وليّ الأمر'
                              when 'whatsapp' then 'واتساب'
                              else 'صندوقُ المنسوبين' end,
      'to_name', coalesce(
         (select v2.fn_display_name(g.full_name) from v2.guardians g where g.id=d.to_guardian),
         (select v2.fn_display_name(pe.full_name) from v2.people pe where pe.id=d.to_person),
         case when d.channel='student_portal'
              then (select v2.fn_display_name(s2.full_name) from v2.students s2 where s2.id=e.student_id)
              else coalesce(v2.role_ar(d.to_role), d.to_role) end),
      'sent_h', case when d.sent_at is null then null else v2.fn_to_hijri(d.sent_at::date)||' هـ' end,
      'seen', (d.read_at is not null),
      'seen_h', case when d.read_at is null then null else v2.fn_to_hijri(d.read_at::date)||' هـ' end,
      'state_ar', case when d.status='failed' then '🔴 لم تُسلَّم — '||coalesce(d.fail_reason,'بلا سبب')
                       when d.read_at is not null then '✅ قُرئت'
                       else '⏳ أُرسلت ولم تُفتح بعد' end) x
      from v2.event_deliveries d join v2.events e on e.id=d.event_id
     where e.school_id = p_school and d.status <> 'cancelled'
       and d.created_at > now() - make_interval(days => greatest(coalesce(p_days,30),1))
     order by d.created_at desc
     limit 300) q;

  return jsonb_build_object('rows', r, 'count', jsonb_array_length(r),
    'sent', v_sent, 'read', v_read, 'failed', v_fail, 'waiting', v_wait,
    'summary_ar', case when coalesce(v_sent,0)=0 then 'لا تسليمَ في هذي المدّة'
      else 'أُرسل '||v2.ar_num(v_sent)||' · قُرئ '||v2.ar_num(coalesce(v_read,0))||
           case when coalesce(v_wait,0)>0 then ' · وينتظر '||v2.ar_num(v_wait) else '' end||
           case when coalesce(v_fail,0)>0 then ' · 🔴 ولم يُسلَّم '||v2.ar_num(v_fail) else '' end end,
    'note_ar','القراءةُ يُثبتها صاحبُها من صفحته — فما لم يُفتح لا يُقال إنّه بلغ');
end $function$
;
