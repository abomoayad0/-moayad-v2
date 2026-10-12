-- فحص ٥٣ · تكليف ⑤: لوحاتُ التوزيع العشر كما تناديها صفحةُ المعلّم — بمعلّمٍ حقيقيّ (الطفيل) وبالنسخ الطويلة وحدَها
-- المدخل · الكفاية · الحساب · البطاقة (له ولغيره) · بلا أسبوع · الحال بفصوله · النقل والحصص والوسم · الدمج وفكّه · المخارج · الإعداد · حدُّ الفصلين
-- وأبوابُ الإدارة وحدّ الفصلين الإداريّ تُردّ عن المعلّم · وكلُّه داخل begin…rollback
begin;
set local lock_timeout = '5s';
set local statement_timeout = '90s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"5e17dd28-15ef-4c80-b7ba-0cb3d9e4141d","role":"authenticated"}';
do $$ declare s jsonb; r0 jsonb; sch uuid := current_setting('t.school')::uuid; begin
  s := public.v2_my_plan_subjects(sch, null::smallint);
  r0 := s->'rows'->0;
  perform set_config('t.g', r0->>'grade', true); perform set_config('t.sub', r0->>'subject_ar', true); perform set_config('t.term', s->>'term', true);
  perform set_config('t.s1','① v2_my_plan_subjects(null) ⇐ '||coalesce(s->>'term_ar','∅')||' · '||coalesce(s->>'summary_ar','∅')||' · أوّلُ سطر: '||coalesce(r0->>'said_ar','∅')
    ||' · sections '||jsonb_array_length(r0->'sections')||' عنصرًا وفيها '||(select count(distinct x->>'section_id') from jsonb_array_elements(r0->'sections') x)||' فصلًا مختلفًا · sections_ar '||coalesce(r0->>'sections_ar','∅'),true);
exception when others then perform set_config('t.s1','① المدخل ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_plan_capacity(current_setting('t.school')::uuid, current_setting('t.g')::smallint);
  perform set_config('t.s2','② v2_plan_capacity ⇐ mine_only '||coalesce(r->>'mine_only','∅')||' · '||coalesce(r->>'scope_ar','∅')||' · سطور '||jsonb_array_length(r->'rows')||' · '||coalesce(r->'rows'->0->>'said_ar','∅'),true);
exception when others then perform set_config('t.s2','② الكفاية ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare b jsonb; begin
  b := public.v2_plan_build(current_setting('t.school')::uuid, current_setting('t.g')::smallint, current_setting('t.sub'), current_setting('t.term')::smallint, null::uuid);
  perform set_config('t.plan', b->>'plan', true);
  perform set_config('t.bneed', coalesce(b->>'periods_need',''), true); perform set_config('t.bcap', coalesce(b->>'capacity',''), true); perform set_config('t.bun', coalesce(b->>'unplaced',''), true);
  perform set_config('t.s3','③ v2_plan_build (طويل · p_person فارغ) ⇐ '||coalesce(b->>'summary_ar','∅')||' ‖ الحاجة '||coalesce(b->>'periods_need','∅')||' · السعة '||coalesce(b->>'capacity','∅')||' · بلا أسبوع '||coalesce(b->>'unplaced','∅'),true);
exception when others then perform set_config('t.s3','③ الحساب ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare c jsonb; it jsonb; it2 jsonb; begin
  c := public.v2_plan_card(current_setting('t.school')::uuid, current_setting('t.g')::smallint, current_setting('t.sub'), current_setting('t.term')::smallint, null::uuid);
  select x into it from jsonb_array_elements(c->'weeks') w, jsonb_array_elements(w->'items') x where x->>'kind'='lesson' limit 1;
  select x into it2 from jsonb_array_elements(c->'weeks') w, jsonb_array_elements(w->'items') x where x->>'kind'='lesson' and x->>'lesson' <> it->>'lesson' limit 1;
  perform set_config('t.l1', it->>'lesson', true); perform set_config('t.l2', it2->>'lesson', true);
  perform set_config('t.sec', c->'sections'->0->>'section', true);
  perform set_config('t.s4','④ v2_plan_card (طويل · لي) ⇐ is_mine '||coalesce(c->>'is_mine','∅')||' · '||coalesce(c->>'status_ar','∅')||' · '||coalesce(c->>'lock_ar','∅')||' · counts_ar '||coalesce((c->'counts_ar')::text,'∅')
    ||' · pending '||jsonb_array_length(coalesce(c->'pending','[]'))||' · counts.unplaced '||coalesce(c->'counts'->>'unplaced','∅')||' · بلا أسبوع في الحساب '||current_setting('t.bun'),true);
exception when others then perform set_config('t.s4','④ البطاقة ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform public.v2_plan_card(current_setting('t.school')::uuid, current_setting('t.g')::smallint, current_setting('t.sub'), current_setting('t.term')::smallint, '62d11d74-7b68-460e-add7-544f1e540df2'::uuid);
  perform set_config('t.s5','⑤ بطاقةُ غيري ⇐ قُبلت',true);
exception when others then perform set_config('t.s5','⑤ بطاقةُ غيري ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_plan_mark(current_setting('t.plan')::uuid, current_setting('t.l1')::uuid, 'done', null, null::smallint, array[current_setting('t.sec')::uuid]);
  perform set_config('t.s6','⑥ v2_plan_mark (طويل · بفصله) ⇐ '||coalesce(r->>'summary_ar','∅')||' · '||coalesce(r->>'done_sections_ar','∅'),true);
exception when others then perform set_config('t.s6','⑥ الحال ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform public.v2_plan_mark(current_setting('t.plan')::uuid, current_setting('t.l2')::uuid, 'deferred', null, null::smallint, null::uuid[]);
  perform set_config('t.s7','⑦ تأجيلٌ بلا سبب ⇐ قُبل',true);
exception when others then perform set_config('t.s7','⑦ تأجيلٌ بلا سبب ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare a jsonb; b jsonb; k jsonb; begin
  a := public.v2_plan_move(current_setting('t.plan')::uuid, current_setting('t.l2')::uuid, 3::smallint, 'سببٌ للفحص');
  b := public.v2_plan_periods(current_setting('t.plan')::uuid, current_setting('t.l2')::uuid, 2::smallint, 'سببٌ للفحص');
  k := public.v2_plan_kind(current_setting('t.plan')::uuid, current_setting('t.l2')::uuid, 'review');
  perform set_config('t.s8','⑧ النقل ⇐ '||coalesce(a->>'summary_ar','∅')||' ‖ الحصص ⇐ '||coalesce(b->>'summary_ar','∅')||' ‖ الوسم ⇐ '||coalesce(k->>'summary_ar','∅'),true);
exception when others then perform set_config('t.s8','⑧ النقل/الحصص/الوسم ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare a jsonb; b jsonb; begin
  perform public.v2_plan_kind(current_setting('t.plan')::uuid, current_setting('t.l2')::uuid, 'lesson');
  a := public.v2_plan_merge(current_setting('t.plan')::uuid, current_setting('t.l2')::uuid, current_setting('t.l1')::uuid, 'سببٌ للفحص');
  b := public.v2_plan_unmerge(current_setting('t.plan')::uuid, current_setting('t.l2')::uuid, 'سببٌ للفحص');
  perform set_config('t.s9','⑨ الدمج ⇐ '||coalesce(a->>'summary_ar','∅')||' ‖ الفكّ ⇐ '||coalesce(b->>'summary_ar','∅'),true);
exception when others then perform set_config('t.s9','⑨ الدمج/الفكّ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare f jsonb; begin
  f := public.v2_plan_fix(current_setting('t.plan')::uuid);
  perform set_config('t.s10','⑩ v2_plan_fix ⇐ الحاجة '||coalesce(f->>'periods_need','∅')||' · السعة '||coalesce(f->>'capacity','∅')||' (الحساب: '||current_setting('t.bneed')||' · '||current_setting('t.bcap')||') · '||coalesce(f->>'unplaced_ar','∅')||' · مقترحاتُ الدمج '||jsonb_array_length(coalesce(f->'merge_suggestions','[]'))||' · حصصٌ فارغة '||jsonb_array_length(coalesce(f->'free_slots','[]')),true);
exception when others then perform set_config('t.s10','⑩ المخارج ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_plan_prepared(current_setting('t.plan')::uuid);
  perform set_config('t.s11','⑪ v2_plan_prepared ⇐ قُبل: '||coalesce(r->>'summary_ar',r::text),true);
exception when others then perform set_config('t.s11','⑪ v2_plan_prepared ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare s jsonb; c jsonb; begin
  s := public.v2_term_split_suggest(current_setting('t.school')::uuid, current_setting('t.g')::smallint, current_setting('t.sub'));
  c := public.v2_term_split_confirm(current_setting('t.school')::uuid, current_setting('t.g')::smallint, current_setting('t.sub'), (s->>'suggest_until_unit')::smallint, 'إقرارٌ للفحص');
  perform set_config('t.s12','⑫ حدُّ الفصلين ⇐ '||coalesce(s->>'summary_ar','∅')||' · fits '||coalesce(s->>'fits','∅')||' · وحداتٌ تسع '||(select count(*) from jsonb_array_elements(s->'units') u where (u->>'fits')::boolean)||' من '||jsonb_array_length(s->'units')||' ‖ الإقرار ⇐ '||coalesce(c->>'summary_ar','∅'),true);
exception when others then perform set_config('t.s12','⑫ حدُّ الفصلين ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform public.v2_term_split_object(current_setting('t.school')::uuid, current_setting('t.g')::smallint, current_setting('t.sub'), null, 3::smallint);
  perform set_config('t.s13','⑬ اعتراضٌ بلا دليل ⇐ قُبل',true);
exception when others then perform set_config('t.s13','⑬ اعتراضٌ بلا دليل ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_curriculum_of(current_setting('t.g')::smallint, current_setting('t.sub'));
  perform set_config('t.s14','⑭ v2_curriculum_of ⇐ '||coalesce(r->>'summary_ar','∅')||' · مفاتيحُ الدرس '||(select string_agg(k,',' order by k) from jsonb_object_keys(r->'rows'->0->'lessons'->0) k)||' · unit_ar '||coalesce(r->'rows'->0->>'unit_ar','∅'),true);
exception when others then perform set_config('t.s14','⑭ المنهج ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform public.v2_plan_review(current_setting('t.plan')::uuid, 'فحص');
  perform set_config('t.s15','⑮ المعلّم · v2_plan_review ⇐ قُبل',true);
exception when others then perform set_config('t.s15','⑮ المعلّم · v2_plan_review ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform public.v2_term_split_set(current_setting('t.g')::smallint, current_setting('t.sub'), 3::smallint, 'فحص', 'فحص');
  perform set_config('t.s16','⑯ المعلّم · v2_term_split_set ⇐ قُبل',true);
exception when others then perform set_config('t.s16','⑯ المعلّم · v2_term_split_set ⇐ رُفض: '||sqlerrm,true); end $$;
reset role;
select n, current_setting('t.s'||n, true) as result from generate_series(1,16) n;
rollback;
