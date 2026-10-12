-- فحص ٥٢ · تكليف ⑤: أبوابُ توزيع المنهج بمعلّمٍ حقيقيّ (علوم أول متوسط في الطفيل) — والنسخُ الطويلةُ وحدَها
-- والصفُّ رقمًا هنا وسيطٌ للفحص لا عرض · وكلُّه داخل begin…rollback (والحسابُ يكتب مسوّدةً تُمحى)
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"5e17dd28-15ef-4c80-b7ba-0cb3d9e4141d","role":"authenticated"}';
do $$ declare me jsonb; begin me := public.v2_me(); perform set_config('t.me', me->>'person_id', true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_plan_weeks(current_setting('t.school')::uuid, 1::smallint);
  perform set_config('t.s1','① v2_plan_weeks(فصل ١) ⇐ '||coalesce(r->>'summary_ar','∅')||' · أوّلُ أسبوع '||coalesce((r->'weeks'->0)::text,'∅'),true);
exception when others then perform set_config('t.s1','① v2_plan_weeks ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_curriculum_of(7::smallint, 'العلوم');
  perform set_config('t.s2','② v2_curriculum_of(أول متوسط · العلوم) ⇐ '||coalesce(r->>'summary_ar','∅')||' · مفاتيح '||(select string_agg(k,',' order by k) from jsonb_object_keys(r) k),true);
exception when others then perform set_config('t.s2','② v2_curriculum_of ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_plan_capacity(current_setting('t.school')::uuid, 7::smallint);
  perform set_config('t.s3','③ المعلّم · v2_plan_capacity ⇐ قُبل: '||coalesce(r->>'summary_ar','∅'),true);
exception when others then perform set_config('t.s3','③ المعلّم · v2_plan_capacity ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_plan_card(current_setting('t.school')::uuid, 7::smallint, 'العلوم', 1::smallint, current_setting('t.me')::uuid);
  perform set_config('t.s4','④ v2_plan_card (الطويلة) قبل الحساب ⇐ '||coalesce(r->>'summary_ar','∅')||' · plan '||coalesce(r->>'plan','∅'),true);
exception when others then perform set_config('t.s4','④ v2_plan_card ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_plan_build(current_setting('t.school')::uuid, 7::smallint, 'العلوم', 1::smallint, current_setting('t.me')::uuid);
  perform set_config('t.s5','⑤ v2_plan_build (الطويلة) ⇐ مفاتيح '||(select string_agg(k,',' order by k) from jsonb_object_keys(r) k)||' ‖ '||coalesce(r->>'summary_ar',left(r::text,300)),true);
exception when others then perform set_config('t.s5','⑤ v2_plan_build ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_plan_card(current_setting('t.school')::uuid, 7::smallint, 'العلوم', 1::smallint, current_setting('t.me')::uuid);
  perform set_config('t.plan', coalesce(r->>'plan',''), true);
  perform set_config('t.s6','⑥ v2_plan_card بعد الحساب ⇐ '||coalesce(r->>'summary_ar','∅')||' · أوّلُ بند '||coalesce((select (x->'items'->0)::text from jsonb_array_elements(r->'weeks') x where jsonb_array_length(x->'items')>0 limit 1),'∅'),true);
exception when others then perform set_config('t.s6','⑥ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_plan_fix(nullif(current_setting('t.plan'),'')::uuid);
  perform set_config('t.s7','⑦ v2_plan_fix ⇐ '||coalesce(r->>'summary_ar',left(r::text,300)),true);
exception when others then perform set_config('t.s7','⑦ v2_plan_fix ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_term_split_suggest(current_setting('t.school')::uuid, 7::smallint, 'العلوم');
  perform set_config('t.s8','⑧ v2_term_split_suggest ⇐ '||coalesce(r->>'summary_ar',left(r::text,300)),true);
exception when others then perform set_config('t.s8','⑧ v2_term_split_suggest ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s9','⑨ v2_plan_card لمعلّمٍ آخر ⇐ قُبل: '||left(public.v2_plan_card(current_setting('t.school')::uuid, 7::smallint, 'العلوم', 1::smallint, '24f3effa-7abb-460d-84e9-a9bae31fda01'::uuid)::text,150),true);
exception when others then perform set_config('t.s9','⑨ v2_plan_card لمعلّمٍ آخر ⇐ رُفض: '||sqlerrm,true); end $$;
reset role;
select n, current_setting('t.s'||n, true) as result from generate_series(1,9) n;
rollback;
