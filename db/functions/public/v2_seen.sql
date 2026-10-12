-- public.v2_seen(p_event uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2538d02b1d5fca7a69e487f17c57aa7c
CREATE OR REPLACE FUNCTION public.v2_seen(p_event uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_me uuid; n int := 0; who text := null; v_stu uuid;
begin
  if auth.uid() is null then
    raise exception 'لا بدّ من تسجيل الدخول — ولا يُقبل إثباتُ القراءة بلا هويّة'; end if;
  select e.student_id into v_stu from v2.events e where e.id = p_event;
  if v_stu is null and not exists (select 1 from v2.events where id=p_event) then
    raise exception 'الحدثُ غيرُ موجود'; end if;

  -- الطالبُ نفسُه
  update v2.event_deliveries d set read_at = coalesce(d.read_at, now()),
         status = case when d.status in ('queued','sent','delivered') then 'read' else d.status end
   where d.event_id = p_event and d.channel = 'student_portal'
     and exists (select 1 from v2.students s
                  where s.id = v_stu and s.user_id = auth.uid() and s.portal_active);
  get diagnostics n = row_count;
  if n > 0 then who := 'الطالب'; end if;

  -- وليُّ أمره
  if n = 0 then
    update v2.event_deliveries d set read_at = coalesce(d.read_at, now()),
           status = case when d.status in ('queued','sent','delivered') then 'read' else d.status end
     where d.event_id = p_event and d.channel = 'guardian_portal'
       and d.to_guardian in (select g.id from v2.guardians g
                              where g.user_id = auth.uid() and coalesce(g.portal_active,true));
    get diagnostics n = row_count;
    if n > 0 then who := 'وليّ الأمر'; end if;
  end if;

  -- المنسوبُ في صندوقه
  if n = 0 then
    v_me := v2.current_person();
    update v2.event_deliveries d set read_at = coalesce(d.read_at, now()),
           status = case when d.status in ('queued','sent','delivered') then 'read' else d.status end
     where d.event_id = p_event and d.channel = 'staff_inbox' and v_me is not null
       and d.to_person = v_me;
    get diagnostics n = row_count;
    if n > 0 then who := 'المنسوب'; end if;
  end if;

  if n = 0 then
    raise exception 'لا تسليمَ لك في هذا الحدث — ولا يُعلّم أحدٌ قراءةَ غيره'; end if;
  return jsonb_build_object('ok',true,'marked',n,'as',who,
    'summary_ar','أُثبتت قراءتُك — '||who);
end $function$
;
