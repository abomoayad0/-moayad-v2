-- فحص ٤٥ · تكليفُ ⑧: لوحةُ الحرمان وقرارُه وإلغاؤه · وقفُ التصعيد ورفعُه والموقوف · إخطاراتُ الغياب
-- 🔑 الحرّاسُ بحساباتٍ غيرِ مالكة (الموجّه · معلّمُ الموادّ · المساعدُ الإداريّ): «للمدير وحدَه» يُرى بالردّ لا بالقبول
-- والمالكُ (بصفة المدير) لا يُثبت حارسًا — يُستعمل لقراءة نصوص الشروط وحدَها، وكلُّه داخل begin…rollback
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
select set_config('t.stu','04335119-5a39-45ad-ac13-4c1988c3034a',true);
set local role authenticated;
-- ① الموجّه: يقرأ اللوحتين · ويُرَدّ عن القرار والوقف والإخطارات
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare r jsonb; begin
  r := public.v2_denial_board(current_setting('t.school')::uuid);
  perform set_config('t.s1','① الموجّه · v2_denial_board ⇐ count '||(r->>'count')||' · counts '||(r->>'counts')||' · '||(r->>'summary_ar')||' ‖ '||(r->>'note_ar'),true);
exception when others then perform set_config('t.s1','① الموجّه · v2_denial_board ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_halted_cases(current_setting('t.school')::uuid);
  perform set_config('t.s2','② الموجّه · v2_halted_cases ⇐ count '||(r->>'count')||' · '||(r->>'summary_ar')||' ‖ '||(r->>'note_ar'),true);
exception when others then perform set_config('t.s2','② الموجّه · v2_halted_cases ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s3','③ الموجّه · v2_denial_decide ⇐ قُبل: '||public.v2_denial_decide(current_setting('t.stu')::uuid,null,'سببٌ مكتوبٌ للفحص')::text,true);
exception when others then perform set_config('t.s3','③ الموجّه · v2_denial_decide ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s4','④ الموجّه · v2_halt_escalation ⇐ قُبل: '||public.v2_halt_escalation(gen_random_uuid(),'سببٌ مكتوبٌ للفحص')::text,true);
exception when others then perform set_config('t.s4','④ الموجّه · v2_halt_escalation ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_absence_notices(current_setting('t.school')::uuid, current_date);
  perform set_config('t.s5','⑤ الموجّه · v2_absence_notices ⇐ قُبل: '||(r->>'summary_ar'),true);
exception when others then perform set_config('t.s5','⑤ الموجّه · v2_absence_notices ⇐ رُفض: '||sqlerrm,true); end $$;
-- ② المساعدُ الإداريّ: اللوحةُ والإخطاراتُ له · والموقوفُ والإلغاءُ لا
set local request.jwt.claims = '{"sub":"fad7dfa7-8f6f-4c5b-9fbf-c0a2c308476a","role":"authenticated"}';
do $$ declare r jsonb; begin
  r := public.v2_absence_notices(current_setting('t.school')::uuid, current_date);
  perform set_config('t.s6','⑥ المساعد · v2_absence_notices اليوم ⇐ '||(r->>'on_date_ar')||' · counts '||(r->>'counts')||' · '||(r->>'summary_ar')||' · citation '||coalesce(r->>'citation_ar','∅')||' · أوّلُ من لم يُخطَر: '||coalesce((r->'not_sent'->0->>'name')||' — '||(r->'not_sent'->0->>'why_ar'),'∅'),true);
exception when others then perform set_config('t.s6','⑥ المساعد · v2_absence_notices ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; d date; begin
  select max(a.on_date) into d from v2.attendance a where a.school_id::text=current_setting('t.school') and a.state='absent';
  r := public.v2_absence_notices(current_setting('t.school')::uuid, d);
  perform set_config('t.s7','⑦ المساعد · v2_absence_notices لآخر يومٍ فيه غائب ⇐ '||coalesce(r->>'on_date_ar','∅')||' · counts '||(r->>'counts')||' · '||(r->>'summary_ar')||' · مفاتيحُ المُخطَر: '||coalesce((select string_agg(k,',' order by k) from jsonb_object_keys(r->'sent'->0) k),'∅')||' · مفاتيحُ غيره: '||coalesce((select string_agg(k,',' order by k) from jsonb_object_keys(r->'not_sent'->0) k),'∅'),true);
exception when others then perform set_config('t.s7','⑦ المساعد · لآخر يومٍ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_denial_board(current_setting('t.school')::uuid);
  perform set_config('t.s8','⑧ المساعد · v2_denial_board ⇐ '||(r->>'summary_ar'),true);
exception when others then perform set_config('t.s8','⑧ المساعد · v2_denial_board ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_halted_cases(current_setting('t.school')::uuid);
  perform set_config('t.s9','⑨ المساعد · v2_halted_cases ⇐ قُبل: '||(r->>'summary_ar'),true);
exception when others then perform set_config('t.s9','⑨ المساعد · v2_halted_cases ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s10','⑩ المساعد · v2_denial_cancel ⇐ قُبل: '||public.v2_denial_cancel(gen_random_uuid(),'سببٌ مكتوبٌ للفحص')::text,true);
exception when others then perform set_config('t.s10','⑩ المساعد · v2_denial_cancel ⇐ رُفض: '||sqlerrm,true); end $$;
-- ③ معلّمُ الموادّ: لا شيءَ منها
set local request.jwt.claims = '{"sub":"5e17dd28-15ef-4c80-b7ba-0cb3d9e4141d","role":"authenticated"}';
do $$ begin
  perform set_config('t.s11','⑪ المعلّم · v2_denial_board ⇐ قُبل: '||(public.v2_denial_board(current_setting('t.school')::uuid)->>'summary_ar'),true);
exception when others then perform set_config('t.s11','⑪ المعلّم · v2_denial_board ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s12','⑫ المعلّم · v2_resume_escalation ⇐ قُبل: '||public.v2_resume_escalation(gen_random_uuid(),'سببٌ مكتوبٌ للفحص')::text,true);
exception when others then perform set_config('t.s12','⑫ المعلّم · v2_resume_escalation ⇐ رُفض: '||sqlerrm,true); end $$;
-- ④ المالكُ: نصوصُ الشروط (لا تُثبت حارسًا)
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
-- المالكُ لا يحمل صفةَ المدير — وحارسُ «المدير وحدَه» يرجع له مبكّرًا بأيّ صفة؛ فبصفة وكيل الطلبة
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ begin
  perform set_config('t.s13','⑬ المالك · v2_denial_decide لطالبٍ لم يبلغ الحدّ ⇐ قُبل: '||public.v2_denial_decide(current_setting('t.stu')::uuid,null,'سببٌ مكتوبٌ للفحص')::text,true);
exception when others then perform set_config('t.s13','⑬ المالك · v2_denial_decide لم يبلغ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s14','⑭ المالك · v2_denial_decide بسببٍ قصير ⇐ قُبل: '||public.v2_denial_decide(current_setting('t.stu')::uuid,null,'قصير')::text,true);
exception when others then perform set_config('t.s14','⑭ المالك · سببٌ قصير ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_form_open(12::smallint, current_setting('t.stu')::uuid, null, null);
  perform set_config('t.s15','⑮ المالك · v2_form_open(12) للطالب — مصدرُ اختيار المحضر ⇐ '||coalesce(r->>'title_ar','∅')||' · entry '||coalesce((r->'entry'->>'status'),'لا محضر'),true);
exception when others then perform set_config('t.s15','⑮ v2_form_open(12) ⇐ رُفض: '||sqlerrm,true); end $$;
reset role;
select n, current_setting('t.s'||n, true) as result from generate_series(1,15) n;
rollback;
