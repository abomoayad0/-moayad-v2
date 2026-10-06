-- فحص ٦ · التعويض: دورةُ الفرصة كاملةً، وفرضُ مسار الشاهد، والحسابُ إلى 86.
-- على الطالب حسمُ 2 (الرصيد 78).
-- • فرصةٌ أولى بممارسةٍ قدرُها 6: يُردّ 2 تعويضًا، ويُكسب 4 تميّزًا، فيصير الرصيد 84.
-- • فرصةٌ ثانية بممارسةٍ قدرُها 2: يُكسب 2 تميّزًا، فيصير الرصيد 86.
-- سقفُ الممارسة قدرُها في الجدول (g_grade_rules · ص١٩)، فلا تُعطى ممارسةٌ قدرُها 6 ثمانيًا.
-- الرئيس مفرح (لجنة التوجيه · وكيل شؤون الطلاب)، والموجّه سعيد. كلُّه داخل begin … rollback.
-- الشاهد: صفٌّ في storage.objects يُدرَج داخل الـ rollback وحده، ولا يُرفع ملفّ.
begin;

with s as (
  select e.student_id, e.year_id, case when e.stage='primary' then 'primary' else 'intermediate_secondary' end scope
  from v2.enrolments e where e.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992' and e.status='active'
  order by e.student_id limit 1),
p as (
  select pr.id from v2.conduct_problems pr, s
  where pr.stage_scope in (s.scope,'all') and pr.mode='onsite'
    and exists (select 1 from v2.conduct_actions a join v2.conduct_degrees d on d.degree_no=a.degree_no
                 where a.degree_no=pr.degree_no and a.stage_scope=pr.stage_scope
                  and a.mode=pr.mode and a.target=pr.target and a.step_no=1 and a.deducts_points and d.deduction=2)
    and not exists (select 1 from v2.behavior_records r where r.student_id=s.student_id and r.problem_id=pr.id
                      and r.year_id=s.year_id and r.status<>'voided')
  order by pr.degree_no, pr.id limit 1)
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.student',(select student_id::text from s),true),
       set_config('t.problem',(select id::text from p),true),
       set_config('t.merit6',(select min(id)::text from v2.conduct_merits where points=6),true),
       set_config('t.merit2',(select min(id)::text from v2.conduct_merits where points=2),true),
       set_config('t.p_chair',(select person_id::text from v2.app_users where id='11be0946-ff39-4eb7-8a74-023b580479be'),true);

-- الحسمُ أوّلًا: الموجّه يدوّن مخالفةً حسمُها 2
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
select public.v2_record_behavior(current_setting('t.student')::uuid, current_setting('t.problem')::int, 'الفصل','فحص') is not null;
reset role;

-- الرئيس
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'يفتح فرصة (merit6)', 'opp', $q$select public.v2_opp_open('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.merit6')::int,null,'فحص','الحصّة الأولى',null::smallint,current_setting('t.p_chair')::uuid)->>'opp'$q$),
    (2, 'يسجّل الطالبَ نيابةً', 'prefix', $q$select public.v2_opp_join(current_setting('t.opp')::uuid,current_setting('t.student')::uuid)->>'upload_to'$q$),
    (3, 'معرّفُ المشاركة من مسار الرفع', 'entry', $q$select split_part(current_setting('t.prefix'),'/',4)$q$),
    (4, 'يملأ النموذجَ والفرصةُ مفتوحة', null::text, $q$select public.v2_entry_file(current_setting('t.entry')::uuid,'شاركتُ',current_setting('t.prefix')||'a.pdf','شهادة')::text$q$),
    (5, 'يُغلق الفرصة', null::text, $q$select public.v2_opp_close(current_setting('t.opp')::uuid,'انتهت')::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الرئيس · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- الشاهد: صفٌّ في المخزن تحت المسار المفروض (يزول بالـ rollback)
insert into storage.objects(bucket_id,name) values ('v2-attachments', current_setting('t.prefix')||'a.pdf');

-- الرئيس
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (6, 'شاهدٌ خارج المسار المفروض', null::text, $q$select public.v2_entry_file(current_setting('t.entry')::uuid,'شاركتُ','merit/x/'||current_setting('t.student')||'/a.pdf','شهادة')::text$q$),
    (7, 'شاهدٌ في المسار لكنّه غيرُ مرفوع', null::text, $q$select public.v2_entry_file(current_setting('t.entry')::uuid,'شاركتُ',current_setting('t.prefix')||'b.pdf','شهادة')::text$q$),
    (8, 'شاهدٌ مرفوعٌ في مساره', null::text, $q$select public.v2_entry_file(current_setting('t.entry')::uuid,'شاركتُ',current_setting('t.prefix')||'a.pdf','شهادة')::text$q$),
    (9, 'يقدّر قبل الإقرار', null::text, $q$select public.v2_entry_grade(current_setting('t.entry')::uuid,6,null)::text$q$),
    (10, 'يُقرّ «نفّذ»', null::text, $q$select public.v2_entry_verdict(current_setting('t.entry')::uuid,'نفّذ','حضر وأدّى',null)::text$q$),
    (11, 'يقدّر 8 لممارسةٍ قدرُها 6', null::text, $q$select public.v2_entry_grade(current_setting('t.entry')::uuid,8,null)::text$q$),
    (12, 'يقدّر 6', null::text, $q$select public.v2_entry_grade(current_setting('t.entry')::uuid,6,null)::text$q$),
    (13, 'يقدّر ثانيةً', null::text, $q$select public.v2_entry_grade(current_setting('t.entry')::uuid,6,null)::text$q$),
    (15, 'يفتح فرصة (merit2)', 'opp2', $q$select public.v2_opp_open('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.merit2')::int,null,'فحص','الحصّة الأولى',null::smallint,current_setting('t.p_chair')::uuid)->>'opp'$q$),
    (16, 'يسجّل الطالبَ نيابةً', 'prefix2', $q$select public.v2_opp_join(current_setting('t.opp2')::uuid,current_setting('t.student')::uuid)->>'upload_to'$q$),
    (17, 'معرّفُ المشاركة من مسار الرفع', 'entry2', $q$select split_part(current_setting('t.prefix2'),'/',4)$q$),
    (18, 'يُغلق الثانية', null::text, $q$select public.v2_opp_close(current_setting('t.opp2')::uuid,'انتهت')::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الرئيس · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

insert into storage.objects(bucket_id,name) values ('v2-attachments', current_setting('t.prefix2')||'a.pdf');

-- الرئيس
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (19, 'شاهدُ الثانية', null::text, $q$select public.v2_entry_file(current_setting('t.entry2')::uuid,'شاركتُ',current_setting('t.prefix2')||'a.pdf','شهادة')::text$q$),
    (20, 'يُقرّ الثانية', null::text, $q$select public.v2_entry_verdict(current_setting('t.entry2')::uuid,'نفّذ','حضر وأدّى',null)::text$q$),
    (21, 'يقدّر 2', null::text, $q$select public.v2_entry_grade(current_setting('t.entry2')::uuid,2,null)::text$q$),
    (22, 'حقُّ الرفع في المسار', null::text, $q$select v2.merit_path_allows(current_setting('t.prefix')||'c.pdf', true)::text$q$),
    (23, 'حقُّ الرفع في مسارٍ ليس لمشاركة', null::text, $q$select v2.merit_path_allows('merit/7a847bb1-9b14-41ad-b9ba-7c8dee61a992/'||current_setting('t.student')||'/00000000-0000-0000-0000-000000000000/c.pdf', true)::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الرئيس · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- الموجّه
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (24, 'حقُّ الرفع في المسار (وليس وكيلًا)', null::text, $q$select v2.merit_path_allows(current_setting('t.prefix')||'c.pdf', true)::text$q$),
    (25, 'حقُّ القراءة في المسار', null::text, $q$select v2.merit_path_allows(current_setting('t.prefix')||'a.pdf', false)::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الموجّه · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", current_setting('t.s'||n, true) as النتيجة from generate_series(1,25) n where n<>14
union all select 'السجلّ', (select string_agg(kind||' '||points, ' · ' order by kind, points) from v2.behavior_ledger
   where student_id=current_setting('t.student')::uuid)
union all select 'المجموع', (select v2.behavior_score(current_setting('t.student')::uuid, o.year_id, o.term_no)::text
   from v2.merit_opportunities o where o.id=nullif(current_setting('t.opp',true),'')::uuid);

rollback;
