-- فحص ٤٦ · تكليفُ ④: جلسةُ الحصّة · شبكةُ الفصل · بطاقةُ الطالب
-- 🔑 بحساباتٍ غيرِ مالكة: معلّمُ الموادّ والموجّه والمساعدُ الإداريّ — ولا حسابَ وكيلٍ غيرِ مالكٍ في القاعدة
-- وكلُّه داخل begin…rollback: فتحُ البطاقة يكتب صفًّا في card_sessions، وفتحُ الحصّة يكتب جلسة — ويُمحى كلُّه
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
set local role authenticated;
-- ① المعلّم
set local request.jwt.claims = '{"sub":"5e17dd28-15ef-4c80-b7ba-0cb3d9e4141d","role":"authenticated"}';
do $$ declare r jsonb; begin
  r := public.v2_my_sessions(current_date);
  perform set_config('t.sec', coalesce(r->0->>'section',''), true);
  perform set_config('t.per', coalesce(r->0->>'period',''), true);
  perform set_config('t.subj', coalesce(r->0->>'subject',''), true);
  perform set_config('t.s1','① المعلّم · v2_my_sessions اليوم ⇐ '||jsonb_array_length(r)||' حصّة · أوّلُها: '||coalesce((r->0)::text,'∅'),true);
exception when others then perform set_config('t.s1','① v2_my_sessions ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; d date; begin
  -- إن لم تكن له حصّةٌ اليومَ فأقربُ يومِ أحدٍ قادم — للقراءة وحدها
  if current_setting('t.sec')='' then
    d := current_date + ((7 - extract(dow from current_date)::int) % 7);
    r := public.v2_my_sessions(d);
    perform set_config('t.sec', coalesce(r->0->>'section',''), true);
    perform set_config('t.subj', coalesce(r->0->>'subject',''), true);
    perform set_config('t.s2','② لا حصّةَ اليومَ — v2_my_sessions('||d||') ⇐ '||jsonb_array_length(r)||' حصّة · أوّلُها: '||coalesce((r->0)::text,'∅'),true);
  else perform set_config('t.s2','② له حصصٌ اليومَ',true); end if;
exception when others then perform set_config('t.s2','② ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_loyalty_of_section(nullif(current_setting('t.sec'),'')::uuid);
  perform set_config('t.stu', coalesce(r->'rows'->0->>'student_id',''), true);
  perform set_config('t.s3','③ v2_loyalty_of_section ⇐ صفوف '||jsonb_array_length(coalesce(r->'rows','[]'))||' · أوّلُها '||coalesce((r->'rows'->0)::text,'∅')||' ‖ '||coalesce(r->>'note_ar','∅'),true);
exception when others then perform set_config('t.s3','③ v2_loyalty_of_section ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_card_open(nullif(current_setting('t.stu'),'')::uuid, current_date);
  perform set_config('t.s4','④ v2_card_open ⇐ مفاتيح: '||(select string_agg(k,',' order by k) from jsonb_object_keys(r) k)
    ||' ‖ can_write '||(r->>'can_write')||' · blocked '||coalesce(r->>'blocked_why','∅')||' · window '||(r->'window')::text
    ||' ‖ tabs: '||(select string_agg((t->>'label_ar')||(case when (t->>'open')::boolean then '✓' else '✗('||coalesce(t->>'why_ar','')||')' end),' | ' order by (t->>'ord')::int) from jsonb_array_elements(r->'tabs') t)
    ||' ‖ glance '||(r->'glance')::text||' ‖ practices '||jsonb_array_length(r->'practices')||' · can_grant '||jsonb_array_length(r->'loyalty'->'can_grant')||' · student '||(r->'student')::text,true);
exception when others then perform set_config('t.s4','④ v2_card_open ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s5','⑤ v2_card_act بـhealth_view ⇐ قُبل: '||public.v2_card_act(nullif(current_setting('t.stu'),'')::uuid,'health_view',null,null,null,'{}'::jsonb)::text,true);
exception when others then perform set_config('t.s5','⑤ v2_card_act بـhealth_view ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s6','⑥ v2_card_act بـhomework ⇐ قُبل: '||public.v2_card_act(nullif(current_setting('t.stu'),'')::uuid,'homework',null,null,null,'{}'::jsonb)::text,true);
exception when others then perform set_config('t.s6','⑥ v2_card_act بـhomework ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_loyalty_catalog();
  perform set_config('t.s7','⑦ v2_loyalty_catalog ⇐ مصادر '||jsonb_array_length(r->'sources')||' (يملك منها '||(select count(*) from jsonb_array_elements(r->'sources') x where (x->>'can_i')::boolean)||') · مكافآت '||jsonb_array_length(r->'rewards')||' (يملك '||(select count(*) from jsonb_array_elements(r->'rewards') x where (x->>'can_i')::boolean)||') · rules '||(r->'rules')::text,true);
exception when others then perform set_config('t.s7','⑦ v2_loyalty_catalog ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare a jsonb; b jsonb; c jsonb; d jsonb; begin
  a := public.v2_roles_of_section(nullif(current_setting('t.sec'),'')::uuid, nullif(current_setting('t.subj'),''));
  b := public.v2_work_board(nullif(current_setting('t.sec'),'')::uuid, nullif(current_setting('t.subj'),''));
  c := public.v2_exit_now(current_setting('t.school')::uuid);
  d := public.v2_card_my_steps(current_setting('t.school')::uuid);
  perform set_config('t.s8','⑧ الشبكة: roles_of_section '||left(a::text,160)||' ‖ work_board '||left(b::text,160)||' ‖ exit_now '||left(c::text,160)||' ‖ card_my_steps '||coalesce(d->>'summary_ar',left(d::text,120)),true);
exception when others then perform set_config('t.s8','⑧ الشبكة ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s9','⑨ v2_session_open لحصّةٍ ليست له (٩) ⇐ قُبل: '||public.v2_session_open(9::smallint,null)::text,true);
exception when others then perform set_config('t.s9','⑨ v2_session_open لحصّةٍ ليست له ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_card_health(nullif(current_setting('t.stu'),'')::uuid, false);
  perform set_config('t.s10','⑩ v2_card_health بلا إقرار ⇐ open '||(r->>'open')||' · '||coalesce(r->>'gate_ar','')||' · ask '||coalesce(r->>'ask_ar','')||' · seconds '||coalesce(r->>'seconds','∅'),true);
exception when others then perform set_config('t.s10','⑩ v2_card_health ⇐ رُفض: '||sqlerrm,true); end $$;
-- ② الموجّه
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare r jsonb; begin
  r := public.v2_my_sessions(current_date);
  perform set_config('t.s11','⑪ الموجّه · v2_my_sessions ⇐ '||jsonb_array_length(r)||' حصّة',true);
exception when others then perform set_config('t.s11','⑪ الموجّه · v2_my_sessions ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_card_open(nullif(current_setting('t.stu'),'')::uuid, current_date);
  perform set_config('t.s12','⑫ الموجّه · v2_card_open ⇐ can_write '||(r->>'can_write')||' · note '||coalesce(r->>'note_ar','∅')||' · مغلق: '||(select count(*) from jsonb_array_elements(r->'tabs') t where not (t->>'open')::boolean),true);
exception when others then perform set_config('t.s12','⑫ الموجّه · v2_card_open ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s13','⑬ الموجّه · v2_card_act ممارسة ⇐ قُبل: '||public.v2_card_act(nullif(current_setting('t.stu'),'')::uuid,'practice','x',null,null,'{}'::jsonb)::text,true);
exception when others then perform set_config('t.s13','⑬ الموجّه · v2_card_act ممارسة ⇐ رُفض: '||sqlerrm,true); end $$;
-- ③ المساعدُ الإداريّ
set local request.jwt.claims = '{"sub":"fad7dfa7-8f6f-4c5b-9fbf-c0a2c308476a","role":"authenticated"}';
do $$ begin
  perform set_config('t.s14','⑭ المساعد · v2_work_set ⇐ قُبل: '||public.v2_work_set(nullif(current_setting('t.sec'),'')::uuid, nullif(current_setting('t.subj'),''),'نصّ','homework',null,current_date+1,null,'class',null,null,null)::text,true);
exception when others then perform set_config('t.s14','⑭ المساعد · v2_work_set ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s15','⑮ المساعد · v2_loyalty_record ⇐ قُبل: '||public.v2_loyalty_record(nullif(current_setting('t.stu'),'')::uuid,'x',null,null)::text,true);
exception when others then perform set_config('t.s15','⑮ المساعد · v2_loyalty_record ⇐ رُفض: '||sqlerrm,true); end $$;
reset role;
select n, current_setting('t.s'||n, true) as result from generate_series(1,15) n;
rollback;
