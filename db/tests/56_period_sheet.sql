-- فحص ٥٦ · لوحة ٤ من «صفّي»: v2_period_states · v2_session_sheet (قارئ) · v2_record_period — والإصلاحاتُ النصّيّة الأخيرة
-- 🔴 لا يُنادى v2_session_attendance هنا: كاتبٌ يُقفل الحضور · بحساب المعلّم الحقيقيّ والموجّه — وكلُّه داخل begin…rollback
begin;
set local lock_timeout = '5s';
set local statement_timeout = '90s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"5e17dd28-15ef-4c80-b7ba-0cb3d9e4141d","role":"authenticated"}';
do $$ declare r jsonb; begin
  r := public.v2_period_states();
  perform set_config('t.s1','① v2_period_states ⇐ '||coalesce(r->>'said_ar','∅')||' · يُختار منها '||(select count(*) from jsonb_array_elements(r->'states') x where (x->>'choosable')::boolean),true);
exception when others then perform set_config('t.s1','① ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare s jsonb; r jsonb; begin
  s := public.v2_my_sessions(current_date);
  perform set_config('t.per', s->0->>'period', true);
  r := public.v2_session_open((s->0->>'period')::smallint, (s->0->>'section')::uuid);
  perform set_config('t.ses', r->>'session', true);
  perform set_config('t.s2','② v2_session_open ⇐ '||coalesce(r->>'msg','∅')||' · وat_ar في الجلسة: '||coalesce(s->0->>'at_ar','∅'),true);
exception when others then perform set_config('t.s2','② ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_session_sheet(current_setting('t.ses')::uuid);
  perform set_config('t.on', r->>'on', true);
  perform set_config('t.st1', r->'students'->0->>'student_id', true); perform set_config('t.st2', r->'students'->1->>'student_id', true);
  perform set_config('t.s3','③ v2_session_sheet ⇐ '||coalesce(r->>'said_ar','∅')||' · '||coalesce(r->>'tally_ar','∅')||' · '||coalesce(r->>'confirmed_ar','∅'),true);
exception when others then perform set_config('t.s3','③ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_record_period(current_setting('t.st1')::uuid, current_setting('t.per')::smallint, 'late', current_setting('t.on')::date, 7::smallint, null);
  r := public.v2_session_sheet(current_setting('t.ses')::uuid);
  perform set_config('t.s4','④ رصدُ «late» بتاريخ الكشف ⇐ قُبل · الطالب: '||coalesce(r->'students'->0->>'said_ar','∅')||' · العدّ: '||coalesce(r->>'tally_ar','∅'),true);
exception when others then perform set_config('t.s4','④ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform public.v2_record_period(current_setting('t.st2')::uuid, current_setting('t.per')::smallint, 'غائب', current_setting('t.on')::date, null, null);
  perform set_config('t.s5','⑤ رصدٌ باللفظ «غائب» ⇐ قُبل',true);
exception when others then perform set_config('t.s5','⑤ رصدٌ باللفظ «غائب» ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform public.v2_record_period(current_setting('t.st2')::uuid, current_setting('t.per')::smallint, 'absent', null, null, null);
  perform set_config('t.s6','⑥ رصدٌ بلا تاريخ ⇐ قُبل',true);
exception when others then perform set_config('t.s6','⑥ رصدٌ بلا تاريخ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_student_timeline(current_setting('t.st1')::uuid, null);
  perform set_config('t.s7','⑦ v2_student_timeline ⇐ on_ar: '||coalesce(r->'events'->0->>'on_ar','∅'),true);
exception when others then perform set_config('t.s7','⑦ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_grade_plan_open(7::smallint,'العلوم',current_setting('t.school')::uuid,1::smallint);
  perform set_config('t.s8','⑧ v2_grade_plan_open ⇐ '||coalesce(r->>'said_ar','∅')||' · kind_ar '||coalesce(r->>'kind_ar','∅'),true);
  perform public.v2_grade_item_add((r->>'plan_id')::uuid,'perf','بندٌ للفحص',5,null);
exception when others then perform set_config('t.s9','⑨ ردُّ نافذة التعديل ⇐ '||sqlerrm,true); end $$;
-- الموجّه: لا يرصد حضورَ حصّةٍ ليست له
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
do $$ begin perform public.v2_act_as('counselor', current_setting('t.school')::uuid);
  perform public.v2_record_period(current_setting('t.st2')::uuid, current_setting('t.per')::smallint, 'absent', current_setting('t.on')::date, null, null);
  perform set_config('t.s10','⑩ الموجّه · v2_record_period ⇐ قُبل',true);
exception when others then perform set_config('t.s10','⑩ الموجّه · v2_record_period ⇐ رُفض: '||sqlerrm,true); end $$;
reset role;
select n, current_setting('t.s'||n, true) as result from generate_series(1,10) n;
rollback;
