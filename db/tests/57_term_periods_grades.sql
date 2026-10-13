-- فحص ٥٧ · تكليف ⑦: فتراتُ الفصل (v2_term_periods · v2_term_periods_set) · ودرجاتُ المادّة بالفترات
-- بالوكيل التعليميّ (فواز) والمعلّم الحقيقيّ والموجّه — وكلُّه داخل begin…rollback
begin;
set local lock_timeout = '5s';
set local statement_timeout = '90s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
set local role authenticated;
-- ① الوكيلُ التعليميّ
set local request.jwt.claims = '{"sub":"24f3effa-7abb-460d-84e9-a9bae31fda01","role":"authenticated"}';
do $$ declare r jsonb; begin
  perform public.v2_act_as('deputy_academic', current_setting('t.school')::uuid);
  r := public.v2_term_periods(current_setting('t.school')::uuid, 1::smallint);
  perform set_config('t.s1','① الوكيل · v2_term_periods ⇐ '||coalesce(r->>'said_ar','∅')||' · '||(select string_agg((x->>'period_ar')||' '||(x->>'from_week_ar')||'←'||(x->>'to_week_ar'),' | ') from jsonb_array_elements(r->'periods') x),true);
exception when others then perform set_config('t.s1','① ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_term_periods_set(1::smallint, array[9,18]::smallint[], current_setting('t.school')::uuid, 'فحصٌ يُمحى');
  perform set_config('t.s2','② الوكيل · الضبطُ [٩،١٨] ⇐ قُبل: '||coalesce(r->>'note_ar','∅'),true);
exception when others then perform set_config('t.s2','② ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform public.v2_term_periods_set(1::smallint, array[9,5]::smallint[], current_setting('t.school')::uuid, 'فحص');
  perform set_config('t.s3','③ نهاياتٌ لا تتصاعد ⇐ قُبل',true);
exception when others then perform set_config('t.s3','③ نهاياتٌ لا تتصاعد ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform public.v2_term_periods_set(1::smallint, array[9,19]::smallint[], current_setting('t.school')::uuid, 'فحص');
  perform set_config('t.s4','④ آخرُ فترةٍ تبتلع أسبوعَ الاختبار ⇐ قُبل',true);
exception when others then perform set_config('t.s4','④ آخرُ فترةٍ في أسبوع الاختبار ⇐ رُفض: '||sqlerrm,true); end $$;
-- ② المعلّم
set local request.jwt.claims = '{"sub":"5e17dd28-15ef-4c80-b7ba-0cb3d9e4141d","role":"authenticated"}';
do $$ begin
  perform public.v2_term_periods_set(1::smallint, array[8,18]::smallint[], current_setting('t.school')::uuid, 'فحص');
  perform set_config('t.s5','⑤ المعلّم · v2_term_periods_set ⇐ قُبل',true);
exception when others then perform set_config('t.s5','⑤ المعلّم · v2_term_periods_set ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_grade_my_subjects(current_setting('t.school')::uuid, null::smallint);
  perform set_config('t.s6','⑥ v2_grade_my_subjects ⇐ '||coalesce(r->>'summary_ar','∅')||' · periods_set '||coalesce(r->>'periods_set','∅'),true);
exception when others then perform set_config('t.s6','⑥ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_grade_plan_open(7::smallint,'العلوم',current_setting('t.school')::uuid,1::smallint);
  perform set_config('t.s7','⑦ v2_grade_plan_open ⇐ '||coalesce(r->>'said_ar','∅'),true);
exception when others then perform set_config('t.s7','⑦ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_grade_plan_card(7::smallint,'العلوم',current_setting('t.school')::uuid,1::smallint,null::uuid);
  perform set_config('t.item', r->'periods'->0->'items'->0->>'id', true);
  perform set_config('t.s8','⑧ البطاقة ⇐ '||coalesce(r->>'said_ar','∅')||' · الخانات '||(select string_agg((b->>'label_ar')||':'||coalesce(b->>'cap','∅'),' | ') from jsonb_array_elements(r->'buckets') b)
    ||' · الفترات '||(select string_agg((x->>'period_ar')||' '||coalesce(x->>'sum_ar','∅'),' | ') from jsonb_array_elements(r->'periods') x)||' · للفصل '||(select string_agg((x->>'title_ar')||(case when (x->>'locked')::boolean then '🔒' else '' end),' | ') from jsonb_array_elements(r->'term_items') x),true);
exception when others then perform set_config('t.s8','⑧ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform public.v2_grade_item_period(current_setting('t.item')::uuid, 2::smallint);
  perform set_config('t.s9','⑨ v2_grade_item_period ⇐ قُبل',true);
exception when others then perform set_config('t.s9','⑨ v2_grade_item_period ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_grade_sheet(7::smallint,'العلوم','أ',current_setting('t.school')::uuid,1::smallint);
  perform set_config('t.stu', r->'students'->0->>'student_id', true);
  perform set_config('t.s10','⑩ الكشف ⇐ '||coalesce(r->>'said_ar','∅')||' · أعمدةٌ بفتراتها: '||(select string_agg(coalesce(x->>'period_ar','للفصل'),'،') from jsonb_array_elements(r->'students'->0->'items') x),true);
exception when others then perform set_config('t.s10','⑩ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_grade_student(current_setting('t.stu')::uuid,7::smallint,'العلوم',current_setting('t.school')::uuid,1::smallint);
  perform set_config('t.s11','⑪ بطاقةُ الطالب ⇐ state '||coalesce(r->>'state','∅')||' · '||(select string_agg((x->>'period_ar')||': '||coalesce(x->>'sum_ar','∅')||' من '||coalesce(x->>'max_ar','∅'),' | ') from jsonb_array_elements(r->'periods') x)
    ||' · النهائيّ: '||coalesce(r->'final'->0->>'bucket_ar','∅')||' · band_ar '||coalesce(r->>'band_ar','لا شيء'),true);
exception when others then perform set_config('t.s11','⑪ ⇐ رُفض: '||sqlerrm,true); end $$;
-- ③ الموجّه
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
do $$ begin perform public.v2_act_as('counselor', current_setting('t.school')::uuid);
  perform public.v2_term_periods_set(1::smallint, array[9,18]::smallint[], current_setting('t.school')::uuid, 'فحص');
  perform set_config('t.s12','⑫ الموجّه · v2_term_periods_set ⇐ قُبل',true);
exception when others then perform set_config('t.s12','⑫ الموجّه · v2_term_periods_set ⇐ رُفض: '||sqlerrm,true); end $$;
reset role;
select n, current_setting('t.s'||n, true) as result from generate_series(1,12) n;
rollback;
