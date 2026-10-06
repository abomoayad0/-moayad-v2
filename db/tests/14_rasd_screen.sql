-- فحص ١٤ · شاشةُ الرصد على القاعدة: قائمةُ السلوكيّات بحقولها · الرصدُ ونصُّه · الحصّة · المرّةُ في اليوم · الغائب · مدرسةٌ أخرى · السلّم والحسم.
-- كلُّه داخل begin … rollback. والغائبُ تجهيزٌ يُكتب في v2.attendance داخل التراجع.
-- الهويّات: مفرح بصفة وكيل شؤون الطلاب في طُفيل · سعيد بصفة الموجّه. لا حساب ولا كلمةَ مرور، ولا حذف.
-- السلوكيّات: 38 «التأخر الصباحي» (مرّةً في اليوم) · 41 «التأخر في الدخول إلى الحصص» (بالحصّة) · 45 «التجمهر أمام البوابة» (بالوقت).
begin;
set local lock_timeout = '5s';
set local statement_timeout = '20s';

select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.year',(select id::text from v2.academic_years where school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid and is_current),true);
select set_config('t.a',(select e.student_id::text from v2.enrolments e where e.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid and e.status='active'
          and not exists (select 1 from v2.behavior_records b where b.student_id=e.student_id and b.problem_id in (38,41,45))
          order by e.student_id limit 1),true),
       set_config('t.b',(select e.student_id::text from v2.enrolments e where e.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid and e.status='active'
          order by e.student_id desc limit 1),true),
       set_config('t.m',(select e.student_id::text from v2.enrolments e where e.school_id='f789f9ea-e474-49bc-86e0-3449258815f8' and e.status='active'
          order by e.student_id limit 1),true);
select set_config('t.a_before',(select count(*)::text from v2.behavior_records where student_id=current_setting('t.a')::uuid),true);

-- تجهيز: الطالبُ «ب» غائبٌ اليوم
insert into v2.attendance(school_id,year_id,term_no,student_id,on_date,state,is_test)
values ('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.year')::uuid,1,current_setting('t.b')::uuid,current_date,'absent',true);

-- الوكيل
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'قائمةُ السلوكيّات للطالب', null::text, $q$select jsonb_array_length(r)||' سلوكًا · needs_period '||(select count(*) from jsonb_array_elements(r) x where (x->>'needs_period')::boolean)||' · once_per_day '||(select count(*) from jsonb_array_elements(r) x where (x->>'once_per_day')::boolean)||' · time '||(select count(*) from jsonb_array_elements(r) x where x->>'repeat_key'='time') from (select public.v2_conduct_list(current_setting('t.a')::uuid) r) z$q$),
    (2, 'حقولُ السلوك 41', null::text, $q$select (select string_agg(k,',' order by k) from jsonb_object_keys(x) k)||' ‖ '||(x->>'degree_ar')||' · '||(x->>'source')||' · needs_period='||(x->>'needs_period')||' · steps='||coalesce(x->>'steps','—')||' · done='||(x->>'done')||' · today='||(x->>'today') from jsonb_array_elements(public.v2_conduct_list(current_setting('t.a')::uuid)) x where (x->>'id')::int=41$q$),
    (3, 'الدرجاتُ كما تُعرض', null::text, $q$select string_agg(distinct x->>'degree_ar',' · ') from jsonb_array_elements(public.v2_conduct_list(current_setting('t.a')::uuid)) x$q$),
    (4, 'يرصد 38 (مرّةً في اليوم)', null::text, $q$select r->>'headline'||' ‖ occ='||(r->>'occurrence')||' · step='||coalesce(r->>'step','—')||' · deducted='||(r->>'deducted')||' · مهامّ: '||coalesce((select string_agg(coalesce(x->>'owner','—'),'،') from jsonb_array_elements(r->'tasks') x),'—') from (select public.v2_record_behavior(current_setting('t.a')::uuid,38,null,null,null) r) z$q$),
    (5, 'يرصد 38 ثانيةً اليوم', null::text, $q$select r->>'headline'||' ‖ occ='||(r->>'occurrence')||' · step='||coalesce(r->>'step','—')||' · deducted='||(r->>'deducted')||' · مهامّ: '||coalesce((select string_agg(coalesce(x->>'owner','—'),'،') from jsonb_array_elements(r->'tasks') x),'—') from (select public.v2_record_behavior(current_setting('t.a')::uuid,38,null,null,null) r) z$q$),
    (6, 'يرصد 41 بلا حصّة', null::text, $q$select r->>'headline'||' ‖ occ='||(r->>'occurrence')||' · step='||coalesce(r->>'step','—')||' · deducted='||(r->>'deducted')||' · مهامّ: '||coalesce((select string_agg(coalesce(x->>'owner','—'),'،') from jsonb_array_elements(r->'tasks') x),'—') from (select public.v2_record_behavior(current_setting('t.a')::uuid,41,null,null,null) r) z$q$),
    (7, 'يرصد 41 · الحصّة ١', null::text, $q$select r->>'headline'||' ‖ occ='||(r->>'occurrence')||' · step='||coalesce(r->>'step','—')||' · deducted='||(r->>'deducted')||' · مهامّ: '||coalesce((select string_agg(coalesce(x->>'owner','—'),'،') from jsonb_array_elements(r->'tasks') x),'—') from (select public.v2_record_behavior(current_setting('t.a')::uuid,41,null,null,1::smallint) r) z$q$),
    (8, 'يرصد 41 · الحصّة ١ ثانيةً', null::text, $q$select r->>'headline'||' ‖ occ='||(r->>'occurrence')||' · step='||coalesce(r->>'step','—')||' · deducted='||(r->>'deducted')||' · مهامّ: '||coalesce((select string_agg(coalesce(x->>'owner','—'),'،') from jsonb_array_elements(r->'tasks') x),'—') from (select public.v2_record_behavior(current_setting('t.a')::uuid,41,null,null,1::smallint) r) z$q$),
    (9, 'يرصد 41 · الحصّة ٢', null::text, $q$select r->>'headline'||' ‖ occ='||(r->>'occurrence')||' · step='||coalesce(r->>'step','—')||' · deducted='||(r->>'deducted')||' · مهامّ: '||coalesce((select string_agg(coalesce(x->>'owner','—'),'،') from jsonb_array_elements(r->'tasks') x),'—') from (select public.v2_record_behavior(current_setting('t.a')::uuid,41,null,null,2::smallint) r) z$q$),
    (10, 'يرصد 41 · الحصّة ٣', null::text, $q$select r->>'headline'||' ‖ occ='||(r->>'occurrence')||' · step='||coalesce(r->>'step','—')||' · deducted='||(r->>'deducted')||' · مهامّ: '||coalesce((select string_agg(coalesce(x->>'owner','—'),'،') from jsonb_array_elements(r->'tasks') x),'—') from (select public.v2_record_behavior(current_setting('t.a')::uuid,41,null,null,3::smallint) r) z$q$),
    (11, 'يرصد 41 · الحصّة ٤', null::text, $q$select r->>'headline'||' ‖ occ='||(r->>'occurrence')||' · step='||coalesce(r->>'step','—')||' · deducted='||(r->>'deducted')||' · مهامّ: '||coalesce((select string_agg(coalesce(x->>'owner','—'),'،') from jsonb_array_elements(r->'tasks') x),'—') from (select public.v2_record_behavior(current_setting('t.a')::uuid,41,null,null,4::smallint) r) z$q$),
    (12, 'يرصد 41 · الحصّة ٥', null::text, $q$select r->>'headline'||' ‖ occ='||(r->>'occurrence')||' · step='||coalesce(r->>'step','—')||' · deducted='||(r->>'deducted')||' · مهامّ: '||coalesce((select string_agg(coalesce(x->>'owner','—'),'،') from jsonb_array_elements(r->'tasks') x),'—') from (select public.v2_record_behavior(current_setting('t.a')::uuid,41,null,null,5::smallint) r) z$q$),
    (13, 'يرصد 41 · الحصّة ٦', null::text, $q$select r->>'headline'||' ‖ occ='||(r->>'occurrence')||' · step='||coalesce(r->>'step','—')||' · deducted='||(r->>'deducted')||' · مهامّ: '||coalesce((select string_agg(coalesce(x->>'owner','—'),'،') from jsonb_array_elements(r->'tasks') x),'—') from (select public.v2_record_behavior(current_setting('t.a')::uuid,41,null,null,6::smallint) r) z$q$),
    (14, 'يرصد 45 (بالوقت)', null::text, $q$select r->>'headline'||' ‖ occ='||(r->>'occurrence')||' · step='||coalesce(r->>'step','—')||' · deducted='||(r->>'deducted')||' · مهامّ: '||coalesce((select string_agg(coalesce(x->>'owner','—'),'،') from jsonb_array_elements(r->'tasks') x),'—') from (select public.v2_record_behavior(current_setting('t.a')::uuid,45,null,null,null) r) z$q$),
    (15, 'يرصد 45 ثانيةً في الساعة', null::text, $q$select r->>'headline'||' ‖ occ='||(r->>'occurrence')||' · step='||coalesce(r->>'step','—')||' · deducted='||(r->>'deducted')||' · مهامّ: '||coalesce((select string_agg(coalesce(x->>'owner','—'),'،') from jsonb_array_elements(r->'tasks') x),'—') from (select public.v2_record_behavior(current_setting('t.a')::uuid,45,null,null,null) r) z$q$),
    (16, 'القائمةُ بعدها: 38 و41', null::text, $q$select string_agg((x->>'id')||': done='||(x->>'done')||' today='||(x->>'today'),' · ') from jsonb_array_elements(public.v2_conduct_list(current_setting('t.a')::uuid)) x where (x->>'id')::int in (38,41)$q$),
    (17, 'يرصد على الغائب', null::text, $q$select r->>'headline'||' ‖ occ='||(r->>'occurrence')||' · step='||coalesce(r->>'step','—')||' · deducted='||(r->>'deducted')||' · مهامّ: '||coalesce((select string_agg(coalesce(x->>'owner','—'),'،') from jsonb_array_elements(r->'tasks') x),'—') from (select public.v2_record_behavior(current_setting('t.b')::uuid,41,null,null,1::smallint) r) z$q$),
    (18, 'يرصد على طالبٍ من مدرسةٍ أخرى', null::text, $q$select r->>'headline'||' ‖ occ='||(r->>'occurrence')||' · step='||coalesce(r->>'step','—')||' · deducted='||(r->>'deducted')||' · مهامّ: '||coalesce((select string_agg(coalesce(x->>'owner','—'),'،') from jsonb_array_elements(r->'tasks') x),'—') from (select public.v2_record_behavior(current_setting('t.m')::uuid,41,null,null,1::smallint) r) z$q$),
    (19, 'قائمةُ السلوكيّات لطالبٍ من مدرسةٍ أخرى', null::text, $q$select jsonb_array_length(public.v2_conduct_list(current_setting('t.m')::uuid))::text$q$),
    (20, 'v2_day_list: الغائبُ وحالُه', null::text, $q$select coalesce((select state||' · '||state_ar from public.v2_day_list('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_date) d where d.student_id=current_setting('t.b')::uuid),'لا يظهر')||' ‖ طلّابُ القائمة '||(select count(*) from public.v2_day_list('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_date))$q$),
    (21, 'بطاقةُ الطالب', null::text, $q$select left((select string_agg(k,',' order by k) from jsonb_object_keys(public.v2_student_card(current_setting('t.a')::uuid)) k),300)$q$),
    (22, 'مهامُّ الطالب', null::text, $q$select left(public.v2_student_tasks(current_setting('t.a')::uuid)::text,300)$q$),
    (23, 'سجلُّه الزمنيّ', null::text, $q$select left(public.v2_student_timeline(current_setting('t.a')::uuid,null)::text,300)$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الوكيل · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- الموجّه
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (24, 'الموجّه يرصد 42 · الحصّة ١', null::text, $q$select r->>'headline'||' ‖ occ='||(r->>'occurrence')||' · step='||coalesce(r->>'step','—')||' · deducted='||(r->>'deducted')||' · مهامّ: '||coalesce((select string_agg(coalesce(x->>'owner','—'),'،') from jsonb_array_elements(r->'tasks') x),'—') from (select public.v2_record_behavior(current_setting('t.a')::uuid,42,null,null,1::smallint) r) z$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الموجّه · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", left(current_setting('t.s'||n),700) as النتيجة from generate_series(1,24) n
union all select 'أ', 'رصداتُ الطالب «أ»: قبل '||current_setting('t.a_before')||' · بعد '||(select count(*) from v2.behavior_records where student_id=current_setting('t.a')::uuid)||' · حسمٌ في الدفتر '||coalesce((select v2.ar_num(-sum(l.points)) from v2.behavior_ledger l join v2.behavior_records r on r.id=l.record_id where r.student_id=current_setting('t.a')::uuid and l.kind='deduction'),'٠')
union all select 'ب', 'ar_num: '||v2.ar_num(2)||' · '||v2.ar_num(80)||' · '||v2.ar_num(2.5)||' · '||v2.ar_num(0)||' · '||v2.ar_num(100)||' ‖ ord_ar(2)='||v2.ord_ar(2)||' · degree_ar(1)='||v2.degree_ar(1);

rollback;
