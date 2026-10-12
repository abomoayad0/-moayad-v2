-- public.v2_my_inbox(p_limit integer)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ac5cddc4cee9665d93dc5ee2758b22e6
CREATE OR REPLACE FUNCTION public.v2_my_inbox(p_limit integer DEFAULT 30)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_me uuid; r jsonb; n_un int := 0; v_kind text := 'none';
begin
  if auth.uid() is null then
    raise exception 'لا بدّ من تسجيل الدخول — ولا صندوقَ بلا هويّة'; end if;
  v_me := v2.current_person();

  select coalesce(jsonb_agg(x order by (x->>'sent_g') desc),'[]'::jsonb) into r from (
    select jsonb_build_object(
      'event', e.id, 'kind', e.kind, 'title', e.title_ar, 'body', e.body_ar,
      'on_h', case when e.on_date is null then null else v2.fn_to_hijri(e.on_date)||' هـ' end,
      'sent_g', d.sent_at, 'sent_h', case when d.sent_at is null then null
                                          else v2.fn_to_hijri(d.sent_at::date)||' هـ' end,
      'seen', (d.read_at is not null),
      'seen_h', case when d.read_at is null then null else v2.fn_to_hijri(d.read_at::date)||' هـ' end,
      'as_ar', case d.channel when 'student_portal' then 'إليك'
                              when 'guardian_portal' then 'إليك بصفتك وليَّ الأمر'
                              else 'إلى صندوقك' end,
      'student', (select v2.fn_display_name(s.full_name) from v2.students s where s.id=e.student_id)) x
      from v2.event_deliveries d
      join v2.events e on e.id = d.event_id
     where d.status <> 'cancelled'
       and ( (d.channel='student_portal'
              and exists (select 1 from v2.students s
                           where s.id=e.student_id and s.user_id=auth.uid() and s.portal_active))
          or (d.channel='guardian_portal'
              and d.to_guardian in (select g.id from v2.guardians g
                                     where g.user_id=auth.uid() and coalesce(g.portal_active,true)))
          or (d.channel='staff_inbox' and v_me is not null and d.to_person = v_me) )
     order by d.sent_at desc nulls last
     limit greatest(coalesce(p_limit,30),1)) q;

  select count(*) into n_un from jsonb_array_elements(r) z
   where coalesce((z->>'seen')::boolean,false) = false;

  select case when exists (select 1 from v2.students s where s.user_id=auth.uid() and s.portal_active)
              then 'student'
              when exists (select 1 from v2.guardians g where g.user_id=auth.uid()) then 'guardian'
              when v_me is not null then 'staff' else 'none' end into v_kind;

  return jsonb_build_object('rows', r, 'count', jsonb_array_length(r),
    'unseen', n_un, 'as', v_kind,
    'summary_ar', case when jsonb_array_length(r)=0 then 'لا شيءَ في صندوقك'
      when n_un=0 then 'قرأتَ كلَّ ما وصلك'
      else v2.ar_count(n_un,'رسالةٌ واحدةٌ لم تُقرأ','رسالتان لم تُقرآ','رسائلَ لم تُقرأ','رسالةً لم تُقرأ') end,
    'note_ar','وإثباتُ القراءة يُسجَّل بتاريخه، ويُعرض لإدارة المدرسة — فما قرأتَه يُعلم أنّه بلغك');
end $function$
;
