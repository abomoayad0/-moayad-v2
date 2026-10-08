-- فحص ٣٧ · بابُ الإثبات العامّ (v2_task_card · v2_task_evidence) · v2_problems بشكله الجديد · نمطُ التعليم في v2_conduct_list
-- داخل begin … rollback — بلا تهيئةٍ خارج الجسور
begin;
set local lock_timeout = '5s';
set local statement_timeout = '40s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
select set_config('t.stu','d4c11fbb-c7d1-4242-954b-519d96aaa9b3',true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'v2_problems (الشكلُ الجديد)', $q$select (r->>'mode')||' · '||(r->>'mode_ar')||' · '||(r->>'note_ar')||' · items '||jsonb_array_length(r->'items') from (select public.v2_problems(current_setting('t.school')::uuid,null) r) z$q$),
    (2, 'v2_conduct_list بنمط المدرسة (p_mode null)', $q$select jsonb_array_length(public.v2_conduct_list(current_setting('t.stu')::uuid,null,'general'))::text$q$),
    (3, 'v2_conduct_list بنمطٍ آخر', $q$select jsonb_array_length(public.v2_conduct_list(current_setting('t.stu')::uuid,'remote','general'))::text$q$),
    (4, 'الرصدات ١–٣ ⇐ auto الثالثة', $q$select string_agg(left(x,400),' ‖ ') from (select (public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,k::smallint)->'auto')::text x, set_config('t.r'||k,'',true) from generate_series(1,3) k) z$q$),
    (5, 'مهامُّ الطالب: door_ar وما يطلبه كلُّ نوع', $q$select string_agg((x->>'kind')||'/'||coalesce(x->>'evidence_kind','∅')||' ['||(x->>'status')||'] ⇐ '||coalesce(x->>'door_ar','∅')||case when (x->>'needs_signature')::boolean then ' · توقيع ('||coalesce(x->>'signer_ar','∅')||')' else '' end||case when x->>'form_no' is not null then ' · نموذج '||(x->>'form_no')||' ready '||(x->>'form_ready') else '' end,' ‖ ' order by (x->>'step')::int,(x->>'ord')::int) from jsonb_array_elements(public.v2_student_tasks(current_setting('t.stu')::uuid)) x where (x->>'step')::int=3$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop;
  perform set_config('t.sign',(select x->>'task' from jsonb_array_elements(public.v2_student_tasks(current_setting('t.stu')::uuid)) x where (x->>'needs_signature')::boolean and x->>'status'='open' and x->>'door_ar'='بابُ الإثبات' limit 1),true);
  perform set_config('t.ntf',(select x->>'task' from jsonb_array_elements(public.v2_student_tasks(current_setting('t.stu')::uuid)) x where x->>'kind'='notify_guardian' limit 1),true);
  for s in select * from (values
    (6, 'v2_task_card لمهمّة توقيع', $q$select (r->'task'->>'kind')||' · door '||(r->>'door')||' · signer '||coalesce(r->>'signer_ar','∅')||' · needs '||(r->'evidence'->'needs')::text||' · labels.sign '||coalesce(r->'evidence'->'labels'->>'sign','∅')||' · refusal '||coalesce(r->'refusal'->>'label_ar','∅')||' · form '||coalesce((r->'form')::text,'∅') from (select public.v2_task_card(nullif(current_setting('t.sign'),'')::uuid) r) z$q$),
    (7, 'v2_task_card لإشعار وليّ الأمر', $q$select public.v2_task_card(nullif(current_setting('t.ntf'),'')::uuid)->>'door'$q$),
    (8, 'الإثباتُ بلا توقيعٍ ولا امتناع', $q$select public.v2_task_evidence(nullif(current_setting('t.sign'),'')::uuid)::text$q$),
    (9, 'الامتناعُ بلا سبب', $q$select public.v2_task_evidence(nullif(current_setting('t.sign'),'')::uuid,null,null,null,null,null,false,null)::text$q$),
    (10, 'الامتناعُ بسببٍ مكتوب (بلا مرفق)', $q$select public.v2_task_evidence(nullif(current_setting('t.sign'),'')::uuid,null,null,null,null,null,false,'رفض الطالبُ التوقيع')->>'note'$q$),
    (11, 'إشعارُ وليّ الأمر من باب الإثبات', $q$select public.v2_task_evidence(nullif(current_setting('t.ntf'),'')::uuid,null,'x')::text$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
select n::text as "#", left(current_setting('t.s'||n),1500) as النتيجة from generate_series(1,11) n;
rollback;
