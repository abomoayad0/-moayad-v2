-- فحص ٥٨ · تكليف ⑧: جملةُ اللجنة (v2_entry_grade · said_ar وألفاظُ الأجزاء والسقوف) · وسندُ v2_my_score
-- تهيئةٌ داخل begin…rollback (فرصةٌ ومشاركةٌ مرفوعةٌ بشاهدٍ في مسارها ومُقرّةٌ لحسام — تُمحى كلُّها) · ثمّ بالموجّه (مقرّرُ لجنة التوجيه) والمساعد الإداريّ (لا مقعدَ له)
begin;
set local lock_timeout = '5s';
set local statement_timeout = '90s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
select set_config('t.stu','04335119-5a39-45ad-ac13-4c1988c3034a',true);
do $$ declare o uuid; e uuid; y uuid; begin
  y := (select id from v2.academic_years where school_id::text = current_setting('t.school') order by (status = 'closed') limit 1);
  insert into v2.merit_opportunities(school_id, merit_id, year_id, term_no, when_ar, kind, state)
    values (current_setting('t.school')::uuid, 1, y, 1, 'فحصٌ يُمحى', 'فرديّة', 'مُغلقة') returning id into o;
  -- المشاركةُ أوّلًا بلا رفع · ثمّ شاهدٌ في مسارها (storage.objects) · ثمّ الرفعُ والإقرار — كما يمرّ بها الطالبُ واللجنة
  insert into v2.merit_entries(opp_id, student_id) values (o, current_setting('t.stu')::uuid) returning id into e;
  insert into storage.objects(bucket_id, name) values ('v2-attachments', v2.evidence_path_for(e) || 'fahs.pdf');
  update v2.merit_entries set filed_at = now(), what_ar = 'فحص', evidence_name = v2.evidence_path_for(e) || 'fahs.pdf', evidence_desc = 'فحص' where id = e;
  update v2.merit_entries set verdict = 'نفّذ', verdict_at = now() where id = e;
  perform set_config('t.entry', e::text, true);
end $$;
set local role authenticated;
-- ① المساعدُ الإداريّ: لا مقعدَ له في لجنة التوجيه
set local request.jwt.claims = '{"sub":"fad7dfa7-8f6f-4c5b-9fbf-c0a2c308476a","role":"authenticated"}';
do $$ begin
  perform public.v2_entry_grade(current_setting('t.entry')::uuid, 6, null);
  perform set_config('t.s1','① المساعد · v2_entry_grade ⇐ قُبل',true);
exception when others then perform set_config('t.s1','① المساعد · v2_entry_grade ⇐ رُفض: '||sqlerrm,true); end $$;
-- ② الموجّه — مقرّرُ لجنة التوجيه
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
do $$ declare r jsonb; g jsonb; begin
  perform public.v2_act_as('counselor', current_setting('t.school')::uuid);
  r := public.v2_entry_grade(current_setting('t.entry')::uuid, 6, null);
  g := r->'الدرجة';
  perform set_config('t.s2','② الموجّه · said_ar ⇐ '||coalesce(r->>'said_ar','∅'),true);
  perform set_config('t.s3','③ الأجزاء ⇐ منح_ar '||coalesce(r->>'منح_ar','∅')||' · تعويض_ar '||coalesce(r->>'تعويض_ar','∅')||' · اكتساب_ar '||coalesce(r->>'اكتساب_ar','∅')||' · مهدور_ar '||coalesce(r->>'مهدور_ar','∅')||' · سند_ar '||coalesce(r->>'سند_ar','∅'),true);
  perform set_config('t.s4','④ الدرجة ⇐ السقوف '||coalesce(g->>'cap_positive','∅')||'/'||coalesce(g->>'cap_merit','∅')||'/'||coalesce(g->>'cap_total','∅')||' · '||coalesce(g->>'positive_ar','∅')||' · '||coalesce(g->>'merit_ar','∅')||' · '||coalesce(g->>'total_ar','∅'),true);
exception when others then perform set_config('t.s2','② الموجّه · v2_entry_grade ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform public.v2_entry_grade(current_setting('t.entry')::uuid, 6, null);
  perform set_config('t.s5','⑤ تقديرٌ ثانٍ ⇐ قُبل',true);
exception when others then perform set_config('t.s5','⑤ تقديرٌ ثانٍ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_my_score(current_setting('t.stu')::uuid, null::smallint);
  perform set_config('t.s6','⑥ v2_my_score ⇐ term_ar '||coalesce(r->>'term_ar','∅')||' · ceiling '||coalesce(r->'what_ar'->>'ceiling','∅')||' · سند '||coalesce(r->'what_ar'->>'سند','∅')||' · merit '||coalesce(r->'what_ar'->>'merit','∅'),true);
exception when others then perform set_config('t.s6','⑥ ⇐ رُفض: '||sqlerrm,true); end $$;
reset role;
select n, current_setting('t.s'||n, true) as result from generate_series(1,6) n;
rollback;
