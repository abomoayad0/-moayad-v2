-- فحص ٤٧ · ملحقُ ⑧: v2_denial_warn · v2_absence_cases_of_student · v2_absence_refer_counselor · v2_form_entries
--          ومفاتيحُ v2_denial_board الجديدة (decision · cancelled · order_ar) و v2_halted_cases (student_id · can_refer)
-- 🔑 بحساباتٍ غيرِ مالكة: المساعدُ الإداريّ · الموجّه · معلّمُ الموادّ — وكلُّه داخل begin…rollback
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
select set_config('t.stu','04335119-5a39-45ad-ac13-4c1988c3034a',true);
-- تهيئة بلا RLS: حالةُ غيابٍ في المدرسة وطالبُها
do $$ begin
  perform set_config('t.case', coalesce((select ac.id::text from v2.absence_cases ac where ac.school_id::text=current_setting('t.school') order by ac.triggered_on desc limit 1),''), true);
  perform set_config('t.cstu', coalesce((select ac.student_id::text from v2.absence_cases ac where ac.id::text=current_setting('t.case')),''), true);
end $$;
set local role authenticated;
-- ① المساعدُ الإداريّ
set local request.jwt.claims = '{"sub":"fad7dfa7-8f6f-4c5b-9fbf-c0a2c308476a","role":"authenticated"}';
do $$ begin
  perform set_config('t.s1','① المساعد · v2_denial_warn لحسام ⇐ قُبل: '||public.v2_denial_warn(current_setting('t.stu')::uuid)::text,true);
exception when others then perform set_config('t.s1','① المساعد · v2_denial_warn لحسام ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s2','② المساعد · v2_absence_refer_counselor ⇐ قُبل: '||public.v2_absence_refer_counselor(coalesce(nullif(current_setting('t.case'),'')::uuid, gen_random_uuid()),'فحص')::text,true);
exception when others then perform set_config('t.s2','② المساعد · v2_absence_refer_counselor ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_absence_cases_of_student(coalesce(nullif(current_setting('t.cstu'),''),current_setting('t.stu'))::uuid);
  perform set_config('t.s3','③ المساعد · v2_absence_cases_of_student ⇐ '||coalesce(r->>'student','')||' · حالات '||jsonb_array_length(r->'rows')||' · مفاتيحُ أولاها: '||coalesce((select string_agg(k,',' order by k) from jsonb_object_keys(r->'rows'->0) k),'∅'),true);
exception when others then perform set_config('t.s3','③ المساعد · v2_absence_cases_of_student ⇐ رُفض: '||sqlerrm,true); end $$;
-- ② الموجّه
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ begin
  perform set_config('t.s4','④ الموجّه · v2_denial_warn ⇐ قُبل: '||public.v2_denial_warn(current_setting('t.stu')::uuid)::text,true);
exception when others then perform set_config('t.s4','④ الموجّه · v2_denial_warn ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  if nullif(current_setting('t.case'),'') is null then
    perform set_config('t.s5','⑤ الموجّه · الإحالة: لا حالةَ غيابٍ في المدرسة — فلم تُجرَّب على حالةٍ حقيقيّة',true);
  else
    perform set_config('t.s5','⑤ الموجّه · v2_absence_refer_counselor على حالةٍ حقيقيّة ⇐ '||public.v2_absence_refer_counselor(current_setting('t.case')::uuid,'فحصٌ يُمحى')::text,true);
  end if;
exception when others then perform set_config('t.s5','⑤ الموجّه · الإحالة ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_form_entries(12::smallint, current_setting('t.stu')::uuid);
  perform set_config('t.s6','⑥ الموجّه · v2_form_entries(12) لحسام ⇐ '||coalesce(r->>'title_ar','')||' · محاضر '||jsonb_array_length(r->'rows')||' ‖ '||coalesce(r->>'note_ar',''),true);
exception when others then perform set_config('t.s6','⑥ الموجّه · v2_form_entries ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_denial_board(current_setting('t.school')::uuid);
  perform set_config('t.s7','⑦ الموجّه · v2_denial_board ⇐ order_ar: '||coalesce(r->>'order_ar','∅')||' · '||(r->>'summary_ar'),true);
exception when others then perform set_config('t.s7','⑦ الموجّه · v2_denial_board ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_halted_cases(current_setting('t.school')::uuid);
  perform set_config('t.s8','⑧ الموجّه · v2_halted_cases ⇐ '||(r->>'summary_ar'),true);
exception when others then perform set_config('t.s8','⑧ الموجّه · v2_halted_cases ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s9','⑨ الموجّه · v2_halt_escalation ⇐ قُبل: '||public.v2_halt_escalation(coalesce(nullif(current_setting('t.case'),'')::uuid, gen_random_uuid()),'سببٌ مكتوبٌ للفحص')::text,true);
exception when others then perform set_config('t.s9','⑨ الموجّه · v2_halt_escalation ⇐ رُفض: '||sqlerrm,true); end $$;
-- ③ معلّمُ الموادّ
set local request.jwt.claims = '{"sub":"5e17dd28-15ef-4c80-b7ba-0cb3d9e4141d","role":"authenticated"}';
do $$ begin
  perform set_config('t.s10','⑩ المعلّم · v2_absence_cases_of_student ⇐ قُبل: '||public.v2_absence_cases_of_student(current_setting('t.stu')::uuid)::text,true);
exception when others then perform set_config('t.s10','⑩ المعلّم · v2_absence_cases_of_student ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s11','⑪ المعلّم · v2_denial_warn ⇐ قُبل: '||public.v2_denial_warn(current_setting('t.stu')::uuid)::text,true);
exception when others then perform set_config('t.s11','⑪ المعلّم · v2_denial_warn ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s12','⑫ المعلّم · v2_absence_refer_counselor ⇐ قُبل: '||public.v2_absence_refer_counselor(coalesce(nullif(current_setting('t.case'),'')::uuid, gen_random_uuid()),'فحص')::text,true);
exception when others then perform set_config('t.s12','⑫ المعلّم · v2_absence_refer_counselor ⇐ رُفض: '||sqlerrm,true); end $$;
reset role;
select n, current_setting('t.s'||n, true) as result from generate_series(1,12) n;
rollback;
