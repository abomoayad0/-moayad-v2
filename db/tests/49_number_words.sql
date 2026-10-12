-- فحص ٤٩ · «كلُّ عددٍ معه نصُّه»: glance (window_ar · absent_ar · late_ar · absent_periods_ar · exits_ar · silent_ar)
--          · correctable[].days_ago_ar · practices[].threshold_ar · practices_note_ar · can_grant[].week_left_ar
--          · v2_loyalty_of_section (كائنٌ و balance_ar) · v2_exit_of_student (today_ar · month_ar · warn_ar) · v2_exit_now · v2_work_kinds.rules_ar
-- بحساب معلّم الموادّ الحقيقيّ · قراءةٌ وحدها داخل begin…rollback (وفتحُ البطاقة يكتب صفًّا يُمحى)
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"5e17dd28-15ef-4c80-b7ba-0cb3d9e4141d","role":"authenticated"}';
do $$ declare r jsonb; begin
  r := public.v2_my_sessions(current_date);
  perform set_config('t.sec', coalesce(r->0->>'section',''), true);
  r := public.v2_loyalty_of_section(nullif(current_setting('t.sec'),'')::uuid);
  perform set_config('t.stu', coalesce(r->'rows'->0->>'student_id',''), true);
  perform set_config('t.s1','① v2_loyalty_of_section ⇐ نوعُه '||jsonb_typeof(r)||' · count '||coalesce(r->>'count','∅')||' · أوّلُ صفّ '||coalesce((r->'rows'->0)::text,'∅'),true);
exception when others then perform set_config('t.s1','① ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_card_open(nullif(current_setting('t.stu'),'')::uuid, current_date);
  perform set_config('t.s2','② glance ⇐ '||(r->'glance')::text,true);
  perform set_config('t.s3','③ practices[0].threshold_ar '||coalesce((select x->>'threshold_ar' from jsonb_array_elements(r->'practices') x where x->>'threshold_ar' is not null limit 1),'∅')||' ‖ practices_note_ar '||coalesce(r->>'practices_note_ar','∅')||' ‖ can_grant[0].week_left_ar '||coalesce(r->'loyalty'->'can_grant'->0->>'week_left_ar','∅')||' ‖ correctable '||jsonb_array_length(r->'correctable')||' ‖ laiha_from.why_ar '||coalesce(r->'laiha_from'->>'why_ar','∅'),true);
  perform set_config('t.s4','④ exits (v2_exit_of_student) ⇐ today_ar '||coalesce(r->'exits'->>'today_ar','∅')||' · month_ar '||coalesce(r->'exits'->>'month_ar','∅')||' · over_warn '||coalesce(r->'exits'->>'over_warn','∅')||' · warn_ar '||coalesce(r->'exits'->>'warn_ar','∅'),true);
exception when others then perform set_config('t.s2','② v2_card_open ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_exit_now(current_setting('t.school')::uuid);
  perform set_config('t.s5','⑤ v2_exit_now ⇐ '||left(r::text,200),true);
exception when others then perform set_config('t.s5','⑤ v2_exit_now ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_work_kinds();
  perform set_config('t.s6','⑥ v2_work_kinds.rules_ar ⇐ '||coalesce(r->>'rules_ar','∅'),true);
exception when others then perform set_config('t.s6','⑥ v2_work_kinds ⇐ رُفض: '||sqlerrm,true); end $$;
reset role;
select n, current_setting('t.s'||n, true) as result from generate_series(1,6) n;
rollback;
