-- فحص ٥٥ · تكليف ⑥: أبوابُ درجات المادّة كما تناديها صفحةُ المعلّم · وأبوابُ تتمّة «صفّي» في بطاقة الحصّة
-- بحساب معلّم الموادّ الحقيقيّ (العلوم · أول متوسط · الطفيل) · والموجّهُ لحارس الرصد — وكلُّه داخل begin…rollback
begin;
set local lock_timeout = '5s';
set local statement_timeout = '90s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"5e17dd28-15ef-4c80-b7ba-0cb3d9e4141d","role":"authenticated"}';
do $$ declare r jsonb; begin
  r := public.v2_grade_my_subjects(current_setting('t.school')::uuid, null::smallint);
  perform set_config('t.term', r->>'term_no', true);
  perform set_config('t.s1','① v2_grade_my_subjects ⇐ '||coalesce(r->>'summary_ar','∅')||' · '||coalesce(r->'rows'->0->>'said_ar','∅')||' · '||coalesce(r->'rows'->0->>'kind_ar','∅'),true);
exception when others then perform set_config('t.s1','① ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_grade_plan_open(7::smallint,'العلوم',current_setting('t.school')::uuid,current_setting('t.term')::smallint);
  perform set_config('t.s2','② v2_grade_plan_open ⇐ '||coalesce(r->>'said_ar','∅'),true);
exception when others then perform set_config('t.s2','② ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_grade_plan_card(7::smallint,'العلوم',current_setting('t.school')::uuid,current_setting('t.term')::smallint,null::uuid);
  perform set_config('t.plan', r->'plan'->>'id', true);
  perform set_config('t.item', (select x->>'id' from jsonb_array_elements(r->'buckets') b, jsonb_array_elements(b->'items') x where not (x->>'locked')::boolean and not (x->>'is_attendance')::boolean and b->>'key'='perf' limit 1), true);
  perform set_config('t.s3','③ v2_grade_plan_card (لي) ⇐ '||coalesce(r->>'said_ar','∅')||' · الخانات '||(select string_agg((b->>'key')||':'||coalesce(b->>'cap','∅')||':'||(b->>'counts'),' ') from jsonb_array_elements(r->'buckets') b)||' · أوّلُ لفظ سقف '||coalesce(r->'buckets'->1->'items'->0->>'max_ar','∅'),true);
exception when others then perform set_config('t.s3','③ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform public.v2_grade_plan_card(7::smallint,'العلوم',current_setting('t.school')::uuid,current_setting('t.term')::smallint,'62d11d74-7b68-460e-add7-544f1e540df2'::uuid);
  perform set_config('t.s4','④ بطاقةُ معلّمٍ آخر ⇐ قُبلت',true);
exception when others then perform set_config('t.s4','④ بطاقةُ معلّمٍ آخر ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform public.v2_grade_item_add(current_setting('t.plan')::uuid,'perf','بندٌ للفحص',5,'observation');
  perform set_config('t.s5','⑤ v2_grade_item_add ⇐ قُبل',true);
exception when others then perform set_config('t.s5','⑤ v2_grade_item_add ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform public.v2_grade_item_drop(current_setting('t.item')::uuid);
  perform set_config('t.s6','⑥ v2_grade_item_drop ⇐ قُبل',true);
exception when others then perform set_config('t.s6','⑥ v2_grade_item_drop ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_reference('assess_tools');
  perform set_config('t.s7','⑦ v2_reference(assess_tools) ⇐ '||jsonb_array_length(r->'items')||' عنصرًا · '||(select string_agg(k||' '||n,' · ') from (select x->>'kind' k, count(*) n from jsonb_array_elements(r->'items') x group by 1) q),true);
exception when others then perform set_config('t.s7','⑦ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; sec text; begin
  sec := (select x->>'section' from jsonb_array_elements(public.v2_my_plan_subjects(current_setting('t.school')::uuid,null::smallint)->'rows') rw, jsonb_array_elements(rw->'sections') x where (rw->>'grade')='7' limit 1);
  r := public.v2_grade_sheet(7::smallint,'العلوم',sec,current_setting('t.school')::uuid,current_setting('t.term')::smallint);
  perform set_config('t.stu', r->'students'->0->>'student_id', true);
  perform set_config('t.att', (select x->>'item_id' from jsonb_array_elements(r->'students'->0->'items') x where (x->>'is_attendance')::boolean limit 1), true);
  perform set_config('t.s8','⑧ v2_grade_sheet بالحرف «'||coalesce(sec,'∅')||'» ⇐ '||coalesce(r->>'said_ar','∅')||' · '||coalesce(r->'students'->0->>'total_ar','∅'),true);
exception when others then perform set_config('t.s8','⑧ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_grade_mark(current_setting('t.item')::uuid, current_setting('t.stu')::uuid, 4);
  perform set_config('t.s9','⑨ v2_grade_mark ⇐ '||coalesce(r->>'said_ar','∅'),true);
exception when others then perform set_config('t.s9','⑨ v2_grade_mark ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform public.v2_grade_mark(current_setting('t.item')::uuid, current_setting('t.stu')::uuid, 999);
  perform set_config('t.s10','⑩ رصدٌ فوق السقف ⇐ قُبل',true);
exception when others then perform set_config('t.s10','⑩ رصدٌ فوق السقف ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform public.v2_grade_mark(current_setting('t.att')::uuid, current_setting('t.stu')::uuid, 5);
  perform set_config('t.s11','⑪ رصدٌ في بند الحضور ⇐ قُبل',true);
exception when others then perform set_config('t.s11','⑪ رصدٌ في بند الحضور ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_grade_student(current_setting('t.stu')::uuid,7::smallint,'العلوم',current_setting('t.school')::uuid,current_setting('t.term')::smallint);
  perform set_config('t.s12','⑫ v2_grade_student ⇐ state '||coalesce(r->>'state','∅')||' · '||coalesce(r->>'state_ar','∅')||' · passes '||coalesce(r->>'passes','لا شيء')||' · band_ar '||coalesce(r->>'band_ar','لا شيء'),true);
exception when others then perform set_config('t.s12','⑫ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare a jsonb; b jsonb; c jsonb; d jsonb; e jsonb; f jsonb; st uuid; begin
  st := current_setting('t.stu')::uuid;
  a := public.v2_practice_scopes(current_setting('t.school')::uuid);
  b := public.v2_badges_of_student(st); c := to_jsonb(public.v2_work_of_student(st)); d := to_jsonb(public.v2_contacts_of(st)); e := public.v2_student_timeline(st, null);
  f := public.v2_advice_for((select (x->>'id')::int from jsonb_array_elements(public.v2_conduct_list(st,null,'general')) x limit 1), null, current_setting('t.school')::uuid);
  perform set_config('t.s13','⑬ «صفّي» بالمعلّم ⇐ المجالات '||jsonb_array_length(a)||' · الشارات: '||coalesce(b->>'count_ar','∅')||' · الأعمال '||jsonb_array_length(c)||' · الاتّصال '||jsonb_array_length(d)||' · السجلّ '||jsonb_array_length(e->'events')||' حدثًا ('||coalesce(e->>'as_ar','∅')||') · النصيحة: '||coalesce(f->>'text','∅'),true);
exception when others then perform set_config('t.s13','⑬ «صفّي» ⇐ رُفض: '||sqlerrm,true); end $$;
-- الموجّه: لا يرصد درجةَ مادّةٍ ليست له
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
do $$ begin perform public.v2_act_as('counselor', current_setting('t.school')::uuid);
  perform public.v2_grade_mark(current_setting('t.item')::uuid, current_setting('t.stu')::uuid, 3);
  perform set_config('t.s14','⑭ الموجّه · v2_grade_mark ⇐ قُبل',true);
exception when others then perform set_config('t.s14','⑭ الموجّه · v2_grade_mark ⇐ رُفض: '||sqlerrm,true); end $$;
reset role;
select n, current_setting('t.s'||n, true) as result from generate_series(1,14) n;
rollback;
