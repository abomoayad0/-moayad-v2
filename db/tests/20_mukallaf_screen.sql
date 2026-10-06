-- فحص ٢٠ · شاشةُ «ما عليّ» (viewK) على القاعدة — ما أُحيل إلى المنسوب، وما عليه من اللجان.
-- تجهيزٌ كفحص ١٨: مفرح يفتح فرصةً يقيمها هو، ويسجّل طالبًا، ويغلقها؛ وصفُّ الملفّ في المخزن والرفعُ داخل التراجع؛ ثمّ يحيل الإقرارَ إلى سعيد.
-- كلُّه داخل begin … rollback. لا رفعَ ولا حذف.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '20s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.saeed',(select person_id::text from v2.app_users where id='52bc11f6-8e82-44cd-9f4d-e9bf43aee128'),true),
       set_config('t.mof',(select person_id::text from v2.app_users where id='11be0946-ff39-4eb7-8a74-023b580479be'),true),
       set_config('t.merit',(select id::text from v2.conduct_merits where points is not null and id<>1 order by id limit 1),true);
select set_config('t.a',(select e.student_id::text from v2.enrolments e where e.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid and e.status='active'
          order by e.student_id limit 1),true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
select set_config('t.opp', public.v2_opp_open(current_setting('t.school')::uuid,current_setting('t.merit')::int,'منظَّمة','فحص ٢٠','الإذاعة · الأحد',null,current_setting('t.mof')::uuid)->>'opp', true);
select set_config('t.entry', split_part(public.v2_opp_join(current_setting('t.opp')::uuid,current_setting('t.a')::uuid)->>'upload_to','/',4), true);
select public.v2_opp_close(current_setting('t.opp')::uuid,'انتهى الوقت');
reset role;
insert into storage.objects(bucket_id,name) values ('v2-attachments', v2.evidence_path_for(current_setting('t.entry')::uuid)||'fixture.png');
update v2.merit_entries set filed_at=now(), what_ar='قدّمتُ فقرة الحديث', evidence_desc='صورة', evidence_name=v2.evidence_path_for(id)||'fixture.png'
 where id=current_setting('t.entry')::uuid;
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
select set_config('t.deleg', public.v2_entry_delegate(current_setting('t.entry')::uuid,current_setting('t.saeed')::uuid,'حضر الإذاعة')::text, true);
reset role;

-- سعيد: «ما عليّ»
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'v2_me: الرأس', $q$select coalesce(r->>'role_ar','—')||' · acting_school='||coalesce(r->>'acting_school','—')||' · mukallaf='||coalesce(r->'can'->>'mukallaf','—')||' · raed='||coalesce(r->'can'->>'raed','—') from (select public.v2_me() r) z$q$),
    (2, 'ما أُحيل إليه (delegated_to_me)', $q$select count(*) filter (where x->>'delegated_to_me'='true')||' من '||count(*)||' · '||coalesce(max(case when x->>'entry'=current_setting('t.entry') then (x->>'student')||' — '||(x->>'merit')||' · '||coalesce(x->>'delegate_note','—') end),'ليست فيه') from jsonb_array_elements(public.v2_entries_pending(current_setting('t.school')::uuid)) x$q$),
    (3, 'يثبت المشاركة: نفّذ', $q$select public.v2_entry_verdict(current_setting('t.entry')::uuid,'نفّذ','حضر وقدّم',null)::text$q$),
    (4, 'ما عليّ من اللجان', $q$select jsonb_array_length(r)::text from (select public.v2_my_committee_tasks(current_setting('t.school')::uuid) r) z$q$),
    (5, 'يقرّ تنفيذَ قرارٍ ليس له', $q$select public.v2_committee_task_done('00000000-0000-0000-0000-000000000000'::uuid,'نفّذت',null)::text$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'سعيد · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", left(current_setting('t.s'||n),1200) as النتيجة from generate_series(1,5) n
union all select 'أ', 'الإحالة: '||coalesce(current_setting('t.deleg'),'—');
rollback;
