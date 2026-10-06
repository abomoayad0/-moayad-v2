-- فحص ١١ · أبوابُ الأساس الستّة: المنسوبون · التكاليف · الطلّابُ والقيد · أولياءُ الأمور · الحساباتُ والبوّابات · بطاقةُ المدرسة.
-- فيه الحالاتُ السبعُ المطلوبة (①–⑦)، وما كشفته قراءةُ الكود. كلُّه داخل begin … rollback.
-- لا يُنشئ حسابًا ولا يمسّ كلمةَ مرور. وإيقافُ الحساب يُجرَّب على النفس وحدها (ويُرفض)،
-- فإيقافُ حسابٍ مثلِك أو أعلى يحتاج هويّةً غيرَ هويّتَي الفحص، فلا يُجرَّب هنا.
-- المعدِّل: مفرح بصفة وكيل شؤون الطلاب في طُفيل. والممنوع: سعيد بصفة الموجّه.
begin;

select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.dup_nid',(select national_id from v2.people p join v2.app_users u on u.person_id=p.id
           where u.id='52bc11f6-8e82-44cd-9f4d-e9bf43aee128'),true),
       set_config('t.new_nid',(select x::text from generate_series(1999999000::bigint,1999999999::bigint) x
           where not exists (select 1 from v2.people where national_id=x::text)
             and not exists (select 1 from v2.students where national_id=x::text) limit 1),true),
       set_config('t.new_sno',(select x::text from generate_series(999990000,999999999) x
           where not exists (select 1 from v2.students where student_no=x::text) limit 1),true),
       set_config('t.section',(select min(section) from v2.enrolments where school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992' and status='active'),true),
       set_config('t.grade',(select min(grade)::text from v2.enrolments where school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992' and status='active'),true),
       set_config('t.post',(select min(key) from v2.posts where key not in ('principal','owner')),true),
       set_config('t.dup_sno',(select s.student_no from v2.students s join v2.enrolments e on e.student_id=s.id
           where e.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992' and e.status='active' and s.student_no is not null order by s.student_no limit 1),true),
       set_config('t.malik_student',(select e.student_id::text from v2.enrolments e
           where e.school_id='f789f9ea-e474-49bc-86e0-3449258815f8' and e.status='active' order by e.student_id limit 1),true),
       set_config('t.malik_person',coalesce((select a.person_id::text from v2.assignments a where a.school_id='f789f9ea-e474-49bc-86e0-3449258815f8' and a.ended_on is null
           and not exists (select 1 from v2.assignments b where b.person_id=a.person_id and b.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992' and b.ended_on is null)
           order by a.person_id limit 1),''),true),
       set_config('t.child',(select student_id::text from v2.guardians where user_id='c62d924e-b3a5-4142-b06b-88836829addb' limit 1),true),
       set_config('t.p_me',(select person_id::text from v2.app_users where id='11be0946-ff39-4eb7-8a74-023b580479be'),true);
select set_config('t.child_before',(select 'بوّابةُ الطالب='||coalesce(s.portal_active::text,'null')||' · بوّاباتُ أوليائه المفتوحة='||
          (select count(*) from v2.guardians g where g.student_id=s.id and g.portal_active)||' · مخالفاتُه='||
          (select count(*) from v2.behavior_records r where r.student_id=s.id)||' · قيودُه='||
          (select count(*) from v2.enrolments e where e.student_id=s.id)
        from v2.students s where s.id=current_setting('t.child')::uuid),true);

-- الموجّه
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'يضيف منسوبًا', null::text, $q$select public.v2_staff_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,'فحص',current_setting('t.new_nid'),null,null,null,null,null,null)::text$q$),
    (2, 'يُنهي قيدَ طالب', null::text, $q$select public.v2_enrolment_end('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.child')::uuid,'نقل',null)::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الموجّه · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- الوكيل
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (3, '① منسوبٌ بهويّةٍ مكرّرة', null::text, $q$select public.v2_staff_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,'منسوب فحص',current_setting('t.dup_nid'),null,null,null,null,null,null)::text$q$),
    (4, 'هويّةٌ تسعةُ أرقام', null::text, $q$select public.v2_staff_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,'منسوب فحص','123456789',null,null,null,null,null,null)::text$q$),
    (5, 'جوّالٌ غيرُ صحيح', null::text, $q$select public.v2_staff_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,'منسوب فحص',null,null,'05ab',null,null,null,null)::text$q$),
    (6, 'يضيف منسوبًا (الوضعُ والملاحظة)', 'add', $q$select public.v2_staff_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,'منسوب فحص',current_setting('t.new_nid'),'E1','0500000000',null,null,null,null)::text$q$),
    (7, 'معرّفُ المضاف', 'newp', $q$select current_setting('t.add')::jsonb->>'person'$q$),
    (8, 'المضافُ في كشف المنسوبين قبل تكليفه؟', null::text, $q$select coalesce((select 'ظاهر · unassigned='||(e->>'unassigned') from jsonb_array_elements(public.v2_staff_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null)) e where e->>'person'=current_setting('t.newp')),'غيرُ ظاهر')$q$),
    (9, 'يعدّل المضافَ وهو بلا تكليف', null::text, $q$select public.v2_staff_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.newp')::uuid,'منسوب فحص ٢',null,null,null,null,null,null,null)->>'mode'$q$),
    (10, '② تكليفٌ بلا رقم خطاب', null::text, $q$select public.v2_assign_add('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.newp')::uuid,current_setting('t.post'),'',null,null,null,null)::text$q$),
    (11, 'تكليفٌ بتاريخ خطابٍ لم يأتِ', null::text, $q$select public.v2_assign_add('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.newp')::uuid,current_setting('t.post'),'بلا رقم',current_date+1,null,null,null)::text$q$),
    (12, 'تكليفٌ «بلا رقم» بلا تاريخ خطاب', null::text, $q$select public.v2_assign_add('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.newp')::uuid,current_setting('t.post'),'بلا رقم',null,null,null,null)::text$q$),
    (13, 'تكليفٌ «بلا رقم» بتاريخ خطاب', 'asg', $q$select public.v2_assign_add('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.newp')::uuid,current_setting('t.post'),'بلا رقم',current_date,null,null,null)->>'assignment'$q$),
    (14, 'تكليفٌ مكرّر', null::text, $q$select public.v2_assign_add('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.newp')::uuid,current_setting('t.post'),'٧',current_date,null,null,null)::text$q$),
    (15, 'المضافُ في الكشف بعد تكليفه', null::text, $q$select exists(select 1 from jsonb_array_elements(public.v2_staff_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null)) e where e->>'person'=current_setting('t.newp'))::text$q$),
    (16, 'إنهاءُ تكليفٍ بسببٍ غيرِ معروف', null::text, $q$select public.v2_assign_end(current_setting('t.asg')::uuid,null,'fired')::text$q$),
    (17, 'إنهاءُ تكليفٍ (transferred)', null::text, $q$select public.v2_assign_end(current_setting('t.asg')::uuid,null,'transferred')::text$q$),
    (18, 'إنهاؤه ثانيةً', null::text, $q$select public.v2_assign_end(current_setting('t.asg')::uuid,null,'other')::text$q$),
    (19, 'طالبٌ برقمِ نورٍ ليس تسعةَ أرقام', null::text, $q$select public.v2_student_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,'طالب فحص','12345',null,null,null,null,null,1::smallint,null)::text$q$),
    (20, 'طالبٌ بلا رقمٍ في نور', null::text, $q$select public.v2_student_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,'طالب فحص',null,null,null,null,null,null,1::smallint,null)::text$q$),
    (21, '③ طالبٌ برقمٍ مكرّر', null::text, $q$select public.v2_student_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,'طالب فحص',current_setting('t.dup_sno'),null,null,null,null,null,1::smallint,null)::text$q$),
    (22, '④ تعديلُ طالبٍ من مدرسةٍ أخرى', null::text, $q$select public.v2_student_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.malik_student')::uuid,'اسم',null,null,null,null,null,null,null,null)::text$q$),
    (23, 'يقيّد طالبًا بجنسٍ غيرِ معروف', null::text, $q$select public.v2_student_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,'طالب فحص',current_setting('t.new_sno'),null,null,null,'M',null,current_setting('t.grade')::smallint,current_setting('t.section'))::text$q$),
    (24, 'يقيّد طالبًا بلا شعبة', null::text, $q$select public.v2_student_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,'طالب فحص',current_setting('t.new_sno'),null,null,null,null,null,1::smallint,null)::text$q$),
    (25, 'يقيّد طالبًا جديدًا بشعبة', 'news', $q$select public.v2_student_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,'طالب فحص',current_setting('t.new_sno'),null,null,null,null,null,current_setting('t.grade')::smallint,current_setting('t.section'))->>'student'$q$),
    (26, 'يعدّل الطالبَ بشعبةٍ فارغة', null::text, $q$select public.v2_student_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.news')::uuid,'طالب فحص',null,null,null,null,null,null,null,'  ')::text$q$),
    (27, '⑤ يوقف حسابَه هو', null::text, $q$select public.v2_account_toggle(current_setting('t.p_me')::uuid,false)::text$q$),
    (28, '⑥ يفتح بوّابةَ طالبٍ بلا حساب', null::text, $q$select public.v2_portal_toggle('student',current_setting('t.news')::uuid,true)::text$q$),
    (29, 'وليٌّ أساسيّ أوّل', 'g1', $q$select public.v2_guardian_save(current_setting('t.news')::uuid,null,'وليّ أوّل','أب',null,'0500000001',null,null,null,true)->>'guardian'$q$),
    (30, 'وليٌّ أساسيّ ثانٍ', null::text, $q$select public.v2_guardian_save(current_setting('t.news')::uuid,null,'وليّ ثانٍ','أمّ',null,'0500000002',null,null,null,true)->>'ok'$q$),
    (31, 'عددُ الأساسيّين', null::text, $q$select (select count(*) from jsonb_array_elements(public.v2_guardians_of(current_setting('t.news')::uuid)) e where (e->>'is_primary')::boolean)||' من '||jsonb_array_length(public.v2_guardians_of(current_setting('t.news')::uuid))$q$),
    (32, 'يفتح بوّابةَ وليٍّ بلا حساب', null::text, $q$select (select (e->>'has_account') from jsonb_array_elements(public.v2_guardians_of(current_setting('t.news')::uuid)) e where e->>'guardian'=current_setting('t.g1'))||' ⇒ '||public.v2_portal_toggle('guardian',current_setting('t.g1')::uuid,true)::text$q$),
    (33, 'أسبابُ الإنهاء من القاعدة', null::text, $q$select (select string_agg((e->>'key')||'='||(e->>'label'),' · ') from jsonb_array_elements(public.v2_enrol_reasons()) e)$q$),
    (34, 'إنهاءٌ بسببٍ عربيّ (نقل)', null::text, $q$select public.v2_enrolment_end('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.child')::uuid,'نقل',null)::text$q$),
    (35, 'إنهاءٌ بـ other بلا نصّ', null::text, $q$select public.v2_enrolment_end('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.child')::uuid,'other',null)::text$q$),
    (36, '⑦ إنهاءُ قيدٍ (transferred)', null::text, $q$select public.v2_enrolment_end('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.child')::uuid,'transferred','فحص')::text$q$),
    (37, 'الطالبُ في الكشف بعد إنهاء قيده', null::text, $q$select exists(select 1 from jsonb_array_elements(public.v2_students_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null,null)) e where e->>'student'=current_setting('t.child'))::text$q$),
    (38, 'إنهاءُ قيد الطالب الجديد (graduated)', null::text, $q$select public.v2_enrolment_end('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.news')::uuid,'graduated',null)->>'reason'$q$),
    (39, 'تكليفُ منسوبٍ من مدرسةٍ أخرى بلا سبب', null::text, $q$select case when current_setting('t.malik_person')='' then 'لا منسوبَ لمالك وحدها' else public.v2_assign_add('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.malik_person')::uuid,current_setting('t.post'),'٨',current_date,null,null,null)::text end$q$),
    (40, 'تكليفُه بسببٍ مكتوب', null::text, $q$select case when current_setting('t.malik_person')='' then 'لا منسوبَ لمالك وحدها' else public.v2_assign_add('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.malik_person')::uuid,current_setting('t.post'),'٨',current_date,null,null,'نُقل إلينا بقرار')->>'ok' end$q$),
    (41, 'ثمّ تعديلُ بياناته', null::text, $q$select case when current_setting('t.malik_person')='' then '—' else public.v2_staff_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.malik_person')::uuid,'اسمٌ آخر',null,null,null,null,null,null,null)->>'mode' end$q$),
    (42, 'كشفُ الحسابات', null::text, $q$select 'منسوبون '||jsonb_array_length(r->'staff')||' · أولياء '||(r->'guardians')::text||' · طلّاب '||(r->'students')::text from (select public.v2_accounts_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992') r) z$q$),
    (43, 'بطاقةُ المدرسة', null::text, $q$select public.v2_school_card('7a847bb1-9b14-41ad-b9ba-7c8dee61a992')::text$q$),
    (44, 'بطاقةُ مدرسةٍ أخرى', null::text, $q$select public.v2_school_card('f789f9ea-e474-49bc-86e0-3449258815f8')::text$q$),
    (45, 'الوظائفُ في الملاك', null::text, $q$select jsonb_array_length(public.v2_posts_list())::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الوكيل · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", left(current_setting('t.s'||n),500) as النتيجة from generate_series(1,45) n
union all select 'أ', 'ابنُ وليّ الفحص قبل الإنهاء: '||current_setting('t.child_before')
union all select 'ب', 'وبعده: '||(select 'بوّابةُ الطالب='||coalesce(s.portal_active::text,'null')||' · بوّاباتُ أوليائه المفتوحة='||
          (select count(*) from v2.guardians g where g.student_id=s.id and g.portal_active)||' · مخالفاتُه='||
          (select count(*) from v2.behavior_records r where r.student_id=s.id)||' · قيودُه='||
          (select count(*) from v2.enrolments e where e.student_id=s.id)||' · آخرُ قيد: '||
          (select e.status||' · '||coalesce(e.end_reason,'') from v2.enrolments e where e.student_id=s.id order by e.created_at desc limit 1)||' · حدثٌ في السجلّ: '||
          coalesce((select ev.title_ar from v2.events ev where ev.student_id=s.id and ev.ref_table='enrolments' order by ev.created_at desc limit 1),'—')
        from v2.students s where s.id=current_setting('t.child')::uuid)
union all select 'ج', 'منسوبُ مالك المختار موجود: '||(nullif(current_setting('t.malik_person'),'') is not null)::text||' · صار اسمُه «اسمٌ آخر»: '||
  coalesce((select (full_name='اسمٌ آخر')::text from v2.people where id=nullif(current_setting('t.malik_person'),'')::uuid),'—');

rollback;
