-- فحص ١٦ · شاشةُ الموجّه (viewM) على القاعدة — بالنداءات نفسها التي ترسلها muwajjih.js وبأشكال معاملاتها.
-- كلُّه داخل begin … rollback: رصدةٌ يدوّنها الوكيل، ثمّ يُفتح منها ملفٌّ للموجّه بالدالّة التي يفتحه بها الحارس.
-- الهويّات: سعيد بصفة الموجّه · مفرح بصفة وكيل شؤون الطلاب. لا حساب ولا كلمةَ مرور، ولا حذف.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '20s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
select set_config('t.a',(select e.student_id::text from v2.enrolments e where e.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid and e.status='active'
          and not exists (select 1 from v2.behavior_records b where b.student_id=e.student_id and b.problem_id=38)
          and not exists (select 1 from v2.counsel_cases c where c.student_id=e.student_id)
          and not exists (select 1 from v2.attendance a where a.student_id=e.student_id and a.on_date=current_date and a.state='absent')
          order by e.student_id limit 1),true);

-- تجهيز: الوكيل يرصد 38
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
select set_config('t.rec', public.v2_record_behavior(current_setting('t.a')::uuid,38,null,null,null)->>'record', true);
reset role;
-- فتحُ الملفّ كما يفتحه الحارسُ عند الإحالة
select set_config('t.case', v2.fn_open_counsel_case(current_setting('t.rec')::uuid)::text, true);
select set_config('t.board_before',(select count(*)::text from v2.counsel_cases where school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid),true);

-- ① الموجّه
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'v2_me للرأس والشريط', $q$select coalesce(r->>'role_ar','—')||' · '||coalesce(r->>'acting_school','—')||' · can.counsel='||coalesce(r->'can'->>'counsel','—')||' · can.record_behavior='||coalesce(r->'can'->>'record_behavior','—') from (select public.v2_me() r) z$q$),
    (2, 'المؤشّر (الكلّ): العدد ومفاتيح الحالة', $q$select jsonb_array_length(r)||' · '||(select string_agg(k,',' order by k) from jsonb_object_keys((select x from jsonb_array_elements(r) x where x->>'case'=current_setting('t.case'))) k)||' ‖ '||(select x::text from jsonb_array_elements(r) x where x->>'case'=current_setting('t.case')) from (select public.v2_counsel_board(current_setting('t.school')::uuid,null) r) z$q$),
    (3, 'المؤشّر بتصفية الحال: قيد / تمّت', $q$select jsonb_array_length(public.v2_counsel_board(current_setting('t.school')::uuid,'قيد المعالجة'))||' / '||jsonb_array_length(public.v2_counsel_board(current_setting('t.school')::uuid,'تمّت المعالجة'))$q$),
    (4, 'بطاقةُ الحالة: المفاتيح والملاحظة', $q$select (select string_agg(k,',' order by k) from jsonb_object_keys(r) k)||' ‖ note='||coalesce(r->>'note','—')||' ‖ written_at='||coalesce(r->'case'->>'written_at','null')||' · sessions='||jsonb_array_length(r->'sessions')||' · records='||jsonb_array_length(r->'records')||' · problem='||(r->'problem')::text||' · deducted='||coalesce(r->>'deducted','—') from (select public.v2_case_card(current_setting('t.case')::uuid) r) z$q$),
    (5, 'جلسةٌ قبل الدراسة', $q$select public.v2_session_add(current_setting('t.case')::uuid,current_date,30::smallint,'نقاش','تحسّنٌ طفيف','التالي')::text$q$),
    (6, 'تقريرٌ قبل الدراسة', $q$select public.v2_case_report(current_setting('t.case')::uuid,'رأي','توصية')::text$q$),
    (7, 'الدراسةُ ناقصة (حقلٌ فارغ كما ترسله الشاشة)', $q$select public.v2_case_write(current_setting('t.case')::uuid,'رأي الطالب','ملاحظ','','خطّة')::text$q$),
    (8, 'الدراسةُ كاملة', $q$select public.v2_case_write(current_setting('t.case')::uuid,'رأي الطالب','ملاحظ','عوامل','خطّة')::text$q$),
    (9, 'تقريرٌ بلا جلسة', $q$select public.v2_case_report(current_setting('t.case')::uuid,'رأي','توصية')::text$q$),
    (10, 'جلسةٌ بلا اختيار استجابة (null كما ترسله الشاشة)', $q$select public.v2_session_add(current_setting('t.case')::uuid,current_date,null,'نقاش',null,'التالي')::text$q$),
    (11, 'جلسةٌ صحيحة', $q$select public.v2_session_add(current_setting('t.case')::uuid,current_date,30::smallint,'نقاش','تحسّنٌ طفيف','التالي')::text$q$),
    (12, 'البطاقة بعد الجلسة: مفاتيحُ الجلسة', $q$select (select string_agg(k,',' order by k) from jsonb_object_keys(r->'sessions'->0) k)||' ‖ '||(r->'sessions'->0)::text from (select public.v2_case_card(current_setting('t.case')::uuid) r) z$q$),
    (13, 'التقرير', $q$select public.v2_case_report(current_setting('t.case')::uuid,'رأي','توصية')::text$q$),
    (14, 'البطاقة بعد التقرير: مفاتيحُ التقرير', $q$select (select string_agg(k,',' order by k) from jsonb_object_keys(r->'report') k)||' · state='||(r->'case'->>'state') from (select public.v2_case_card(current_setting('t.case')::uuid) r) z$q$),
    (15, 'المؤشّر بعد التقرير: الحالةُ في «تمّت»', $q$select (select x->>'state' from jsonb_array_elements(public.v2_counsel_board(current_setting('t.school')::uuid,'تمّت المعالجة')) x where x->>'case'=current_setting('t.case'))||' · reported='||(select x->>'reported' from jsonb_array_elements(public.v2_counsel_board(current_setting('t.school')::uuid,null)) x where x->>'case'=current_setting('t.case'))$q$),
    (16, 'سجلُّ الملفّ بصفة counselor', $q$select (r->>'as_ar')||' · '||jsonb_array_length(r->'events')||' · '||coalesce((select string_agg(e->>'kind',',') from jsonb_array_elements(r->'events') e),'') from (select public.v2_student_timeline(current_setting('t.a')::uuid,'counselor') r) z$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الموجّه · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- ② الوكيل (مفرح، وهو مالك): لا يرى الشاشةَ ولا ما وراءها
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (17, 'v2_me: can.counsel', $q$select coalesce(r->>'role_ar','—')||' · can.counsel='||coalesce(r->'can'->>'counsel','—') from (select public.v2_me() r) z$q$),
    (18, 'المؤشّر', $q$select public.v2_counsel_board(current_setting('t.school')::uuid,null)::text$q$),
    (19, 'بطاقةُ الحالة', $q$select public.v2_case_card(current_setting('t.case')::uuid)::text$q$),
    (20, 'جلسة', $q$select public.v2_session_add(current_setting('t.case')::uuid,current_date,null,'نقاش','تحسّنٌ طفيف','التالي')::text$q$),
    (21, 'سجلُّ الملفّ بصفة counselor (يطلبها ولا يملكها)', $q$select (r->>'as_ar')||' · '||jsonb_array_length(r->'events')||' · '||coalesce((select string_agg(e->>'kind',',') from jsonb_array_elements(r->'events') e),'') from (select public.v2_student_timeline(current_setting('t.a')::uuid,'counselor') r) z$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الوكيل · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", left(current_setting('t.s'||n),1200) as النتيجة from generate_series(1,21) n
union all select 'أ', 'الطالب: '||current_setting('t.a')||' · الرصدة: '||coalesce(current_setting('t.rec'),'—')||' · الحالة: '||coalesce(current_setting('t.case'),'—');
rollback;
