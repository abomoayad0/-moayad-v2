-- فحص ٢٥ · مهامُّ الطالب بحقولها ونموذجها · وإثباتُ الاتّصال يُقفل مهمّةَ «إشعار وليّ الأمر» — بالنداءات التي ترسلها wakeel.js و tasks.js.
-- كلُّه داخل begin … rollback. لا حسابَ يُمسّ ولا حذف.
-- تجهيز: لا مهمّةَ notify_guardian في البيانات (كلُّها other)، فتُجعل مهمّةٌ مفتوحةٌ notify_guardian داخل التراجع.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '20s';
select set_config('t.task',(select t.id::text from v2.behavior_tasks t join v2.behavior_records br on br.id=t.record_id
          where t.status='open' and br.status<>'voided' order by t.id limit 1),true);
select set_config('t.stu',(select br.student_id::text from v2.behavior_tasks t join v2.behavior_records br on br.id=t.record_id where t.id=current_setting('t.task')::uuid),true),
       set_config('t.school',(select br.school_id::text from v2.behavior_tasks t join v2.behavior_records br on br.id=t.record_id where t.id=current_setting('t.task')::uuid),true);
update v2.behavior_tasks set kind='notify_guardian' where id=current_setting('t.task')::uuid;

set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'مهامُّ الطالب: العددُ والمفاتيح', $q$select jsonb_array_length(r)||' مهمّة ‖ '||(select string_agg(k,',' order by k) from jsonb_object_keys(r->0) k) from (select public.v2_student_tasks(current_setting('t.stu')::uuid) r) z$q$),
    (2, 'المهمّةُ المجهّزة: النوعُ والنموذجُ والإثبات', $q$select x->>'kind'||' · form_no='||coalesce(x->>'form_no','∅')||' · '||coalesce(x->>'form_title','∅')||' · evidence='||coalesce(x->>'evidence_kind','∅')||' · needs: date='||(x->>'needs_date')||' text='||(x->>'needs_text')||' file='||(x->>'needs_file')||' ref='||(x->>'needs_ref')||' people='||(x->>'needs_people')||' sign='||(x->>'needs_signature')||' · status='||(x->>'status') from jsonb_array_elements(public.v2_student_tasks(current_setting('t.stu')::uuid)) x where x->>'task'=current_setting('t.task')$q$),
    (3, 'مهمّةٌ من نوع other: النموذج', $q$select coalesce(string_agg(distinct coalesce(x->>'form_no','∅')||'/'||coalesce(x->>'form_title','∅'),' | '),'—') from jsonb_array_elements(public.v2_student_tasks(current_setting('t.stu')::uuid)) x where x->>'kind'='other'$q$),
    (4, 'اتّصال: لم يردّ (مع المهمّة)', $q$select public.v2_contact_log(current_setting('t.stu')::uuid,current_setting('t.task')::uuid,'هاتف','لم يردّ','اتّصلتُ ولم يُجب',null,null)::text$q$),
    (5, 'اتّصال: ردّ وعلم (مع المهمّة)', $q$select public.v2_contact_log(current_setting('t.stu')::uuid,current_setting('t.task')::uuid,'هاتف','ردّ وعلم','أُبلغ بالمخالفة','سأتابعه',null)::text$q$),
    (6, 'المهمّةُ بعدُ', $q$select (x->>'status')||' · ev_on='||coalesce(x->>'ev_on','∅')||' · ev_text='||coalesce(x->>'ev_text','∅')||' · done_by='||coalesce(x->>'done_by','∅') from jsonb_array_elements(public.v2_student_tasks(current_setting('t.stu')::uuid)) x where x->>'task'=current_setting('t.task')$q$),
    (7, 'أحداثُ guardian_contact في سجلّ الطالب', $q$select count(*)::text||' · '||coalesce(max(e->>'title'),'—') from jsonb_array_elements(public.v2_student_timeline(current_setting('t.stu')::uuid,null)->'events') e where e->>'kind'='guardian_contact'$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
select n::text as "#", left(current_setting('t.s'||n),1500) as النتيجة from generate_series(1,7) n
union all select 'أ', 'task '||current_setting('t.task')||' · student '||current_setting('t.stu')||' · school '||current_setting('t.school')
union all select 'ب', 'أحداثٌ guardian_contact في الجدول لهذا الطالب: '||(select count(*) from v2.events where student_id=current_setting('t.stu')::uuid and kind='guardian_contact');
rollback;
