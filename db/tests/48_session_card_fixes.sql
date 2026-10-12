-- فحص ٤٨ · تصحيحُ ④: v2_session_lesson_options · v2_work_kinds · v2_card_open (class_ar · silent_ar · health_from)
-- بحساب معلّم الموادّ الحقيقيّ · وفتحُ الحصّة تهيئةٌ داخل begin…rollback
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"5e17dd28-15ef-4c80-b7ba-0cb3d9e4141d","role":"authenticated"}';
do $$ declare r jsonb; begin
  r := public.v2_my_sessions(current_date);
  perform set_config('t.sec', coalesce(r->0->>'section',''), true);
  perform set_config('t.per', coalesce(r->0->>'period',''), true);
  perform set_config('t.s1','① v2_my_sessions ⇐ '||jsonb_array_length(r)||' · أوّلُها الحصّة '||coalesce(r->0->>'period','∅'),true);
exception when others then perform set_config('t.s1','① ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_session_open(nullif(current_setting('t.per'),'')::smallint, nullif(current_setting('t.sec'),'')::uuid);
  perform set_config('t.sess', coalesce(r->>'session',''), true);
  perform set_config('t.s2','② v2_session_open (تهيئة) ⇐ '||coalesce(r->>'msg',r::text),true);
exception when others then perform set_config('t.s2','② v2_session_open ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_session_lesson_options(nullif(current_setting('t.sess'),'')::uuid);
  perform set_config('t.s3','③ v2_session_lesson_options ⇐ '||coalesce(r->>'grade_ar','∅')||' · '||coalesce(r->>'subject_ar','∅')||' · plan_status_ar '||coalesce(r->>'plan_status_ar','∅')||' · بنود '||jsonb_array_length(r->'rows')||' ‖ '||coalesce(r->>'note_ar','∅'),true);
exception when others then perform set_config('t.s3','③ v2_session_lesson_options ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_work_kinds();
  perform set_config('t.s4','④ v2_work_kinds ⇐ kinds '||(select string_agg((x->>'code')||'='||(x->>'label_ar')||coalesce(' ('||(x->>'note_ar')||')',''),' · ') from jsonb_array_elements(r->'kinds') x)||' ‖ scopes '||(r->'scopes')::text||' ‖ rules '||(r->'rules')::text,true);
exception when others then perform set_config('t.s4','④ v2_work_kinds ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; st uuid; begin
  select (x->>'student_id')::uuid into st from jsonb_array_elements(public.v2_loyalty_of_section(nullif(current_setting('t.sec'),'')::uuid)->'rows') x limit 1;
  r := public.v2_card_open(st, current_date);
  perform set_config('t.s5','⑤ v2_card_open ⇐ student '||(r->'student')::text||' ‖ glance '||(r->'glance')::text||' ‖ health_from '||coalesce((r->'health_from')::text,'∅'),true);
exception when others then perform set_config('t.s5','⑤ v2_card_open ⇐ رُفض: '||sqlerrm,true); end $$;
reset role;
select n, current_setting('t.s'||n, true) as result from generate_series(1,5) n;
rollback;
