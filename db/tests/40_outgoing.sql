-- فحص ٤٠ · بريدُ الصادر (تكليفُ الشاشات ③): ما ينتظر · الإنشاءُ وحرّاسُه · التوقيعُ برقمه · الإخراجُ وحرّاسُه · الجواب · الإقفال · الإلغاءُ وحارسُ ما خرج · السجلّ والسرّيّ
-- كلُّه داخل begin…rollback — بهويّة مفرح (وكيلًا) والمدير — ولا يبقى منه شيء
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
select set_config('t.k1','2d13dd2b-a60d-4fa7-ac2e-4726f0d7e30e',true);   -- edu_report
select set_config('t.k2','e2f1e4be-c9c4-4100-ad73-082338f262ca',true);   -- edu_decision
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, '① ما ينتظر (قبل)', $q$select (r->'counts')::text||' ‖ '||(r->>'summary_ar')||' ‖ أوّلُ بند: '||coalesce(r->'tasks_without_letter'->0->>'kind','∅')||' · '||coalesce(r->'tasks_without_letter'->0->>'need_ar','∅')||' ‖ '||(r->>'note_ar') from (select public.v2_outgoing_pending(current_setting('t.school')::uuid) r) z$q$),
    (2, '② إنشاءٌ بلا موضوع', $q$select public.v2_outgoing_create(' ','إدارة التعليم')::text$q$),
    (3, '③ ينتظر جوابًا بلا موعد', $q$select public.v2_outgoing_create('موضوع','إدارة التعليم',null,'report','عادي',true,null)::text$q$),
    (4, '④ إنشاءُ خطابٍ يحمل بندين', $q$select (set_config('t.m1', r->>'mail', true) is not null)::text||' '||(r->>'serial_ar')||' · '||(r->>'state_ar')||' · '||(r->>'kind_ar')||' · بنود '||jsonb_array_length(r->'tasks')||' ['||(select string_agg((x->>'kind')||': '||(x->>'closes_on_ar'),' | ') from jsonb_array_elements(r->'tasks') x)||'] ‖ '||(r->>'note_ar') from (select public.v2_outgoing_create('رفعُ محضر لجنة التوجيه','إدارة التعليم بمحافظة الطائف','نصّ','report','عادي',true,current_date+7,null,null,null,array[current_setting('t.k1')::uuid,current_setting('t.k2')::uuid]) r) z$q$),
    (5, '⑤ إنشاءُ خطابٍ سرّيّ', $q$select (set_config('t.m2', r->>'mail', true) is not null)::text||' '||(r->>'secrecy')||' · '||(r->>'state_ar') from (select public.v2_outgoing_create('شأنٌ سرّيّ','إدارة التعليم',null,'letter','سري') r) z$q$),
    (6, '⑥ الوكيلُ يوقّع', $q$select public.v2_outgoing_sign(nullif(current_setting('t.m1'),'')::uuid)::text$q$),
    (7, '⑦ ما ينتظر (بعد الإنشاء)', $q$select (r->'counts')::text||' ‖ '||(r->>'summary_ar') from (select public.v2_outgoing_pending(current_setting('t.school')::uuid) r) z$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
set local request.jwt.claims = '{"sub":"62d11d74-7b68-460e-add7-544f1e540df2","role":"authenticated"}';
select public.v2_act_as('principal', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (8, '⑧ المديرُ يوقّع', $q$select (r->>'serial_ar')||' · '||(r->>'state_ar')||' · '||coalesce(r->>'issued_ar','∅')||' ‖ '||(r->>'note_ar') from (select public.v2_outgoing_sign(nullif(current_setting('t.m1'),'')::uuid) r) z$q$),
    (9, '⑨ إخراجٌ بلا قناة', $q$select public.v2_outgoing_send(nullif(current_setting('t.m1'),'')::uuid,null)::text$q$),
    (10, '⑩ «نظام رسمي» بلا مرجع', $q$select public.v2_outgoing_send(nullif(current_setting('t.m1'),'')::uuid,'نظام رسمي')::text$q$),
    (11, '⑪ الإخراج', $q$select (r->>'state_ar')||' · بنود ['||(select string_agg((x->>'kind')||'='||(x->>'status'),' | ') from jsonb_array_elements(r->'tasks') x)||'] ‖ '||(r->>'note_ar') from (select public.v2_outgoing_send(nullif(current_setting('t.m1'),'')::uuid,'نظام رسمي','TS-1447-55') r) z$q$),
    (12, '⑫ إلغاءُ ما خرج', $q$select public.v2_outgoing_cancel(nullif(current_setting('t.m1'),'')::uuid,'خطأ')::text$q$),
    (13, '⑬ إقفالٌ قبل الجواب', $q$select public.v2_outgoing_close(nullif(current_setting('t.m1'),'')::uuid)::text$q$),
    (14, '⑭ جوابٌ بلا مرجعٍ ولا خلاصة', $q$select public.v2_outgoing_reply(nullif(current_setting('t.m1'),'')::uuid)::text$q$),
    (15, '⑮ الجواب', $q$select (r->>'state_ar')||' · closed '||coalesce(r->>'closed','∅')||' · بنود ['||(select string_agg((x->>'kind')||'='||(x->>'status'),' | ') from jsonb_array_elements(r->'tasks') x)||'] ‖ '||(r->>'note_ar') from (select public.v2_outgoing_reply(nullif(current_setting('t.m1'),'')::uuid,current_date,'R-9','قرّر المدير…') r) z$q$),
    (16, '⑯ الإقفال', $q$select (r->>'state_ar')||' ‖ '||(r->>'note_ar') from (select public.v2_outgoing_close(nullif(current_setting('t.m1'),'')::uuid,'تمّ') r) z$q$),
    (17, '⑰ إلغاءُ السرّيّ بلا سبب', $q$select public.v2_outgoing_cancel(nullif(current_setting('t.m2'),'')::uuid,' ')::text$q$),
    (18, '⑱ إلغاءُ السرّيّ', $q$select (r->>'state_ar')||' ‖ '||(r->>'note_ar') from (select public.v2_outgoing_cancel(nullif(current_setting('t.m2'),'')::uuid,'كُتب خطأً') r) z$q$),
    (19, '⑲ السجلّ', $q$select (r->>'summary_ar')||' · '||(select string_agg((x->>'serial_ar')||' · '||(x->>'subject')||' · '||(x->>'status'),' | ') from jsonb_array_elements(r->'rows') x where x->>'mail' in (current_setting('t.m1'),current_setting('t.m2')))||' ‖ '||(r->>'note_ar') from (select public.v2_outgoing_register(current_setting('t.school')::uuid) r) z$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (20, '⑳ الوكيلُ يفتح السرّيّ', $q$select public.v2_outgoing_one(nullif(current_setting('t.m2'),'')::uuid)::text$q$),
    (21, '㉑ إرفاقٌ على المُقفل', $q$select public.v2_outgoing_attach(nullif(current_setting('t.m1'),'')::uuid,'link','رابط','https://x')::text$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||left(coalesce(r,'—'),200);
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
select n, current_setting('t.s'||n, true) as result from generate_series(1,21) n;
rollback;
