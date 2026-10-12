-- فحص ٥٠ · الألفاظُ من الباب (المحفظة · البطاقة · لوحة الحرمان · الموقوف · حالات الغياب) · وحسابا المدير والوكيل
-- 🔑 المديرُ صار يعمل بتكليفه (لا بمنحةٍ تتجاوز الحرّاس) — فقبولُه هنا يُثبت الحارس · والوكيلُ (فواز · الشؤون التعليميّة) يُردّ عمّا ليس له
-- وكلُّه داخل begin…rollback: الوقفُ ورفعُه على حالةٍ حقيقيّةٍ يُمحيان
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
select set_config('t.stu','04335119-5a39-45ad-ac13-4c1988c3034a',true);
do $$ begin
  perform set_config('t.case', coalesce((select ac.id::text from v2.absence_cases ac where ac.school_id::text=current_setting('t.school') and not coalesce(ac.escalation_halted,false) order by ac.triggered_on desc limit 1),''), true);
  perform set_config('t.cstu', coalesce((select ac.student_id::text from v2.absence_cases ac where ac.id::text=current_setting('t.case')),''), true);
end $$;
set local role authenticated;
-- ① المعلّم: ألفاظُ البطاقة والمحفظة
set local request.jwt.claims = '{"sub":"5e17dd28-15ef-4c80-b7ba-0cb3d9e4141d","role":"authenticated"}';
do $$ declare r jsonb; st uuid; begin
  select (x->>'student_id')::uuid into st from jsonb_array_elements(public.v2_loyalty_of_section((public.v2_my_sessions(current_date)->0->>'section')::uuid)->'rows') x limit 1;
  perform set_config('t.tstu', st::text, true);
  r := public.v2_card_open(st, current_date);
  perform set_config('t.s1','① البطاقة ⇐ balance_ar '||coalesce(r->'loyalty'->>'balance_ar','∅')||' · can_grant[0] '||coalesce((r->'loyalty'->'can_grant'->0)::text,'∅')
    ||' · practices[0].points_ar '||coalesce(r->'practices'->0->>'points_ar','∅')||' · threshold_ar (بلا مدّة) '||coalesce((select x->>'threshold_ar' from jsonb_array_elements(r->'practices') x where x->>'threshold_ar' is not null limit 1),'∅'),true);
  perform set_config('t.s2','② practice_balance ⇐ '||coalesce((r->'practice_balance')::text,'∅'),true);
exception when others then perform set_config('t.s1','① البطاقة ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_loyalty_wallet(current_setting('t.tstu')::uuid);
  perform set_config('t.s3','③ v2_loyalty_wallet ⇐ مفاتيح '||(select string_agg(k,',' order by k) from jsonb_object_keys(r) k)||' · balance_ar '||coalesce(r->>'balance_ar','∅')||' · totals_ar '||coalesce(r->>'totals_ar','∅'),true);
exception when others then perform set_config('t.s3','③ v2_loyalty_wallet ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_loyalty_catalog();
  perform set_config('t.s4','④ v2_loyalty_catalog ⇐ '||(select string_agg((x->>'title_ar')||'['||coalesce(x->>'auto_kind','∅')||' · can_i '||(x->>'can_i')||']',' | ') from jsonb_array_elements(r->'sources') x where x->>'auto_kind' <> 'manual'),true);
exception when others then perform set_config('t.s4','④ v2_loyalty_catalog ⇐ رُفض: '||sqlerrm,true); end $$;
-- ② المدير بتكليفه
set local request.jwt.claims = '{"sub":"62d11d74-7b68-460e-add7-544f1e540df2","role":"authenticated"}';
do $$ begin perform public.v2_act_as('principal', current_setting('t.school')::uuid); perform set_config('t.pact','صفةُ المدير في الطفيل ✓',true);
exception when others then perform set_config('t.pact','act_as(principal) ⇐ '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_denial_board(current_setting('t.school')::uuid);
  perform set_config('t.s5','⑤ المدير · v2_denial_board ⇐ '||(r->>'summary_ar')||' · مفاتيحُ الصفّ: '||coalesce((select string_agg(k,',' order by k) from jsonb_object_keys(r->'rows'->0) k),'لا صفّ'),true);
exception when others then perform set_config('t.s5','⑤ المدير · v2_denial_board ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_absence_cases_of_student(nullif(current_setting('t.cstu'),'')::uuid);
  perform set_config('t.s6','⑥ المدير · v2_absence_cases_of_student ⇐ '||coalesce(r->>'student','')||' · days_ar '||coalesce(r->'rows'->0->>'days_ar','∅')||' · tasks_ar '||coalesce(r->'rows'->0->>'tasks_ar','∅'),true);
exception when others then perform set_config('t.s6','⑥ المدير · v2_absence_cases_of_student ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_halt_escalation(nullif(current_setting('t.case'),'')::uuid, 'ظرفٌ أسريٌّ للفحص يُمحى');
  perform set_config('t.s7','⑦ المدير · v2_halt_escalation على حالةٍ حقيقيّة ⇐ قُبل: '||coalesce(r->>'note_ar',''),true);
exception when others then perform set_config('t.s7','⑦ المدير · v2_halt_escalation ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_halted_cases(current_setting('t.school')::uuid);
  perform set_config('t.s8','⑧ المدير · v2_halted_cases بعد الوقف ⇐ '||(r->>'summary_ar')||' · days_ar '||coalesce(r->'rows'->0->>'days_ar','∅')||' · open_tasks_ar '||coalesce(r->'rows'->0->>'open_tasks_ar','∅')||' · can_refer '||coalesce(r->'rows'->0->>'can_refer','∅'),true);
exception when others then perform set_config('t.s8','⑧ المدير · v2_halted_cases ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_resume_escalation(nullif(current_setting('t.case'),'')::uuid, 'زال الظرفُ — فحصٌ يُمحى');
  perform set_config('t.s9','⑨ المدير · v2_resume_escalation ⇐ قُبل: '||coalesce(r->>'note_ar',''),true);
exception when others then perform set_config('t.s9','⑨ المدير · v2_resume_escalation ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s10','⑩ المدير · v2_denial_decide لحسام ⇐ قُبل: '||public.v2_denial_decide(current_setting('t.stu')::uuid,null,'سببٌ مكتوبٌ للفحص')::text,true);
exception when others then perform set_config('t.s10','⑩ المدير · v2_denial_decide لحسام ⇐ رُفض: '||sqlerrm,true); end $$;
-- ③ الوكيلُ للشؤون التعليميّة (فواز)
set local request.jwt.claims = '{"sub":"24f3effa-7abb-460d-84e9-a9bae31fda01","role":"authenticated"}';
do $$ begin perform public.v2_act_as('deputy_academic', current_setting('t.school')::uuid); perform set_config('t.dact','صفةُ الوكيل التعليميّ في الطفيل ✓',true);
exception when others then perform set_config('t.dact','act_as(deputy_academic) ⇐ '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s11','⑪ الوكيل التعليميّ · v2_denial_board ⇐ قُبل: '||(public.v2_denial_board(current_setting('t.school')::uuid)->>'summary_ar'),true);
exception when others then perform set_config('t.s11','⑪ الوكيل التعليميّ · v2_denial_board ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s12','⑫ الوكيل التعليميّ · v2_halt_escalation ⇐ قُبل: '||public.v2_halt_escalation(nullif(current_setting('t.case'),'')::uuid,'سببٌ مكتوبٌ للفحص')::text,true);
exception when others then perform set_config('t.s12','⑫ الوكيل التعليميّ · v2_halt_escalation ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s13','⑬ الوكيل التعليميّ · v2_students_find ⇐ '||(public.v2_students_find('حس',null,null,5,current_setting('t.school')::uuid)->>'summary_ar'),true);
exception when others then perform set_config('t.s13','⑬ الوكيل التعليميّ · v2_students_find ⇐ رُفض: '||sqlerrm,true); end $$;
reset role;
select n, current_setting('t.s'||n, true) as result from generate_series(1,13) n
union all select 98, current_setting('t.pact',true) union all select 99, current_setting('t.dact',true);
rollback;
