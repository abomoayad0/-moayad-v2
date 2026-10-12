-- فحص ٥٤ · ردُّ وكيل القاعدة على بلاغ ٥٣: v2_plan_vocab · ألفاظُ النصوص في أبواب التوزيع · تكرارُ الفصول · ألفاظُ المنهج
-- وإعادةُ ما لم يثبت في ٥٣ (سببُ الإعادة: خطأُ تصميمٍ في ٥٣ لا عيبٌ ثابت):
--   الدمجُ وفكُّه على درسين بحصّةٍ واحدة · وحارسُ v2_plan_review بعد إعلان الإعداد (فلا يُردّ لعدم الإعداد)
-- بحساب المعلّم الحقيقيّ — وكلُّه داخل begin…rollback
begin;
set local lock_timeout = '5s';
set local statement_timeout = '90s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"5e17dd28-15ef-4c80-b7ba-0cb3d9e4141d","role":"authenticated"}';
do $$ declare r jsonb; begin
  r := public.v2_plan_vocab();
  perform set_config('t.s1','① v2_plan_vocab ⇐ الأحوال '||(select string_agg(x->>'label_ar',' · ' order by (x->>'ord')::int) from jsonb_array_elements(r->'states') x)
    ||' ‖ الأنواع '||(select string_agg(x->>'label_ar',' · ' order by (x->>'ord')::int) from jsonb_array_elements(r->'kinds') x)||' ‖ حالُ الخطّة '||jsonb_array_length(r->'statuses'),true);
exception when others then perform set_config('t.s1','① v2_plan_vocab ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare s jsonb; begin
  s := public.v2_my_plan_subjects(current_setting('t.school')::uuid, null::smallint);
  perform set_config('t.g', s->'rows'->0->>'grade', true); perform set_config('t.sub', s->'rows'->0->>'subject_ar', true); perform set_config('t.term', s->>'term', true);
  perform set_config('t.s2','② تكرارُ الفصول ⇐ '||(select string_agg((x->>'subject_ar')||' '||(x->>'grade_ar')||': عناصر '||jsonb_array_length(x->'sections')||' · sections_n '||(x->>'sections_n'),' | ') from jsonb_array_elements(s->'rows') x),true);
exception when others then perform set_config('t.s2','② المدخل ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_curriculum_of(current_setting('t.g')::smallint, current_setting('t.sub'));
  perform set_config('t.s3','③ v2_curriculum_of ⇐ '||coalesce(r->>'periods_total_ar','∅')||' · '||coalesce(r->'rows'->0->>'said_ar','∅')||' · '||coalesce(r->'rows'->0->'lessons'->0->>'no_ar','∅')||' · '||coalesce(r->'rows'->0->'lessons'->0->>'periods_ar','∅'),true);
exception when others then perform set_config('t.s3','③ المنهج ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare b jsonb; c jsonb; begin
  b := public.v2_plan_build(current_setting('t.school')::uuid, current_setting('t.g')::smallint, current_setting('t.sub'), current_setting('t.term')::smallint, null::uuid);
  perform set_config('t.plan', b->>'plan', true);
  c := public.v2_plan_card(current_setting('t.school')::uuid, current_setting('t.g')::smallint, current_setting('t.sub'), current_setting('t.term')::smallint, null::uuid);
  perform set_config('t.l1', (select x->>'lesson' from jsonb_array_elements(c->'weeks') w, jsonb_array_elements(w->'items') x where x->>'kind'='lesson' order by (w->>'week_no')::int, (x->>'ord')::int limit 1), true);
  perform set_config('t.l2', (select x->>'lesson' from jsonb_array_elements(c->'weeks') w, jsonb_array_elements(w->'items') x where x->>'kind'='lesson' order by (w->>'week_no')::int, (x->>'ord')::int offset 1 limit 1), true);
  perform set_config('t.pend', coalesce((select string_agg(x->>'lesson',',') from jsonb_array_elements(c->'pending') x),''), true);
  perform set_config('t.s4','④ الحساب ⇐ قُبل · بلا أسبوع '||coalesce(b->>'unplaced','∅'),true);
exception when others then perform set_config('t.s4','④ الحساب ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare a jsonb; b jsonb; k jsonb; begin
  a := public.v2_plan_move(current_setting('t.plan')::uuid, current_setting('t.l2')::uuid, 3::smallint, 'سببٌ للفحص');
  b := public.v2_plan_periods(current_setting('t.plan')::uuid, current_setting('t.l2')::uuid, 1::smallint, 'سببٌ للفحص');
  k := public.v2_plan_kind(current_setting('t.plan')::uuid, current_setting('t.l2')::uuid, 'review');
  perform public.v2_plan_kind(current_setting('t.plan')::uuid, current_setting('t.l2')::uuid, 'lesson');
  perform set_config('t.s5','⑤ النقل ⇐ '||coalesce(a->>'summary_ar','∅')||' ‖ الحصص ⇐ '||coalesce(b->>'summary_ar','∅')||' ‖ الوسم ⇐ '||coalesce(k->>'summary_ar','∅'),true);
exception when others then perform set_config('t.s5','⑤ النقل/الحصص/الوسم ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform public.v2_plan_move(current_setting('t.plan')::uuid, current_setting('t.l2')::uuid, 99::smallint, 'سببٌ للفحص');
  perform set_config('t.s6','⑥ نقلٌ إلى أسبوعٍ ليس في الفصل ⇐ قُبل',true);
exception when others then perform set_config('t.s6','⑥ نقلٌ إلى أسبوعٍ ليس في الفصل ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare a jsonb; b jsonb; begin
  perform public.v2_plan_periods(current_setting('t.plan')::uuid, current_setting('t.l1')::uuid, 1::smallint, 'سببٌ للفحص');
  a := public.v2_plan_merge(current_setting('t.plan')::uuid, current_setting('t.l2')::uuid, current_setting('t.l1')::uuid, 'سببٌ للفحص');
  b := public.v2_plan_unmerge(current_setting('t.plan')::uuid, current_setting('t.l2')::uuid, 'سببٌ للفحص');
  perform set_config('t.s7','⑦ الدمجُ (درسان بحصّةٍ واحدة) ⇐ '||coalesce(a->>'summary_ar','∅')||' ‖ الفكّ ⇐ '||coalesce(b->>'summary_ar','∅'),true);
exception when others then perform set_config('t.s7','⑦ الدمج/الفكّ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare f jsonb; begin
  f := public.v2_plan_fix(current_setting('t.plan')::uuid);
  perform set_config('t.s8','⑧ v2_plan_fix ⇐ term_ar '||coalesce(f->>'term_ar','∅')||' · '||coalesce(f->>'summary_ar','∅'),true);
exception when others then perform set_config('t.s8','⑧ المخارج ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform public.v2_plan_prepared(current_setting('t.plan')::uuid);
  perform set_config('t.s9','⑨ الإعدادُ وفيها بلا أسبوع ⇐ قُبل',true);
exception when others then perform set_config('t.s9','⑨ الإعدادُ وفيها بلا أسبوع ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare l text; r jsonb; begin
  foreach l in array string_to_array(nullif(current_setting('t.pend'),''),',') loop
    perform public.v2_plan_move(current_setting('t.plan')::uuid, l::uuid, 18::smallint, 'سببٌ للفحص');
  end loop;
  r := public.v2_plan_prepared(current_setting('t.plan')::uuid);
  perform set_config('t.s10','⑩ الإعدادُ بعد نقل ما بلا أسبوع ⇐ قُبل: '||coalesce(r->>'summary_ar',r::text),true);
exception when others then perform set_config('t.s10','⑩ الإعدادُ بعد النقل ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform public.v2_plan_review(current_setting('t.plan')::uuid, 'فحص');
  perform set_config('t.s11','⑪ المعلّم · v2_plan_review بعد الإعداد ⇐ قُبل',true);
exception when others then perform set_config('t.s11','⑪ المعلّم · v2_plan_review بعد الإعداد ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare s jsonb; c jsonb; o jsonb; begin
  s := public.v2_term_split_suggest(current_setting('t.school')::uuid, current_setting('t.g')::smallint, current_setting('t.sub'));
  c := public.v2_term_split_confirm(current_setting('t.school')::uuid, current_setting('t.g')::smallint, current_setting('t.sub'), (s->>'suggest_until_unit')::smallint, 'إقرارٌ للفحص');
  o := public.v2_term_split_object(current_setting('t.school')::uuid, current_setting('t.g')::smallint, current_setting('t.sub'), 'دليلٌ للفحص', 2::smallint);
  perform set_config('t.s12','⑫ الإقرار ⇐ '||coalesce(c->>'summary_ar','∅')||' ‖ الاعتراض ⇐ '||coalesce(o->>'summary_ar','∅'),true);
exception when others then perform set_config('t.s12','⑫ حدُّ الفصلين ⇐ رُفض: '||sqlerrm,true); end $$;
reset role;
select n, current_setting('t.s'||n, true) as result from generate_series(1,12) n
union all select 13, '⑬ مسحٌ: رقمٌ لاتينيٌّ في النتائج ⇐ '||case when (select string_agg(current_setting('t.s'||n,true),' ') from generate_series(1,12) n) ~ '[0-9]' then 'وُجد' else 'لا' end;
rollback;
