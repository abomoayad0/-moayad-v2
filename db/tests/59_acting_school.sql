-- فحص ٥٩ · تكليف ⑨: الصفةُ ومدرستُها — v2_me (acting_chosen · acting_school · acting_school_ar · roles[].can_act · why_ar) · و v2_act_as يلزمه المدرسة
-- بالمعلّم الحقيقيّ والوكيل التعليميّ (فواز) — وكلُّه داخل begin…rollback
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"5e17dd28-15ef-4c80-b7ba-0cb3d9e4141d","role":"authenticated"}';
do $$ declare r jsonb; begin
  r := public.v2_me();
  perform set_config('t.s1','① المعلّم · v2_me ⇐ acting_chosen '||coalesce(r->>'acting_chosen','∅')||' · acting_school_ar '||coalesce(r->>'acting_school_ar','∅')||' · الصفات: '||(select string_agg((x->>'role_ar')||' | '||(x->>'source')||' | '||coalesce(x->>'school','∅')||' | can_act '||coalesce(x->>'can_act','∅'),' ‖ ') from jsonb_array_elements(r->'roles') x),true);
exception when others then perform set_config('t.s1','① ⇐ رُفض: '||sqlerrm,true); end $$;
set local request.jwt.claims = '{"sub":"24f3effa-7abb-460d-84e9-a9bae31fda01","role":"authenticated"}';
do $$ declare r jsonb; begin
  r := public.v2_me();
  perform set_config('t.s2','② الوكيل · v2_me ⇐ acting_chosen '||coalesce(r->>'acting_chosen','∅')||' · acting_school_ar '||coalesce(r->>'acting_school_ar','∅')||' · الصفات: '||(select string_agg((x->>'role_ar')||' | '||(x->>'source')||' | '||coalesce(x->>'school','∅')||' | can_act '||coalesce(x->>'can_act','∅')||coalesce(' | '||(x->>'why_ar'),''),' ‖ ') from jsonb_array_elements(r->'roles') x),true);
  perform set_config('t.blocked', coalesce((select (x->>'role_key')||'|'||coalesce(x->>'school_id','') from jsonb_array_elements(r->'roles') x where (x->>'can_act')::boolean is false limit 1),''), true);
exception when others then perform set_config('t.s2','② ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform public.v2_act_as('deputy_academic', null);
  perform set_config('t.s3','③ الوكيل · v2_act_as بلا مدرسة ⇐ قُبل · '||coalesce(public.v2_me()->>'acting_school_ar','∅'),true);
exception when others then perform set_config('t.s3','③ الوكيل · v2_act_as بلا مدرسة ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  perform public.v2_act_as('deputy_academic', current_setting('t.school')::uuid);
  r := public.v2_me();
  perform set_config('t.s4','④ الوكيل · v2_act_as بمدرسة ⇐ قُبل · acting_chosen '||coalesce(r->>'acting_chosen','∅')||' · '||coalesce(r->>'acting_school_ar','∅'),true);
exception when others then perform set_config('t.s4','④ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  if current_setting('t.blocked') = '' then perform set_config('t.s5','⑤ لا صفةَ can_act=false عند الوكيل — فلم يُجرَّب اختيارُها',true); return; end if;
  perform public.v2_act_as(split_part(current_setting('t.blocked'),'|',1), nullif(split_part(current_setting('t.blocked'),'|',2),'')::uuid);
  perform set_config('t.s5','⑤ اختيارُ صفةٍ can_act=false ⇐ قُبل',true);
exception when others then perform set_config('t.s5','⑤ اختيارُ صفةٍ can_act=false ⇐ رُفض: '||sqlerrm,true); end $$;
reset role;
select n, current_setting('t.s'||n, true) as result from generate_series(1,5) n;
rollback;
