-- فحص ٤ · الإرشاد: سرّيّةُ دراسة الحالة وحرّاسُ تسلسلها.
-- الموجّه: سعيد (مرشدٌ في طُفيل). المالك: مفرح (owner) — والسرّيّةُ تُغلق عليه أيضًا.
-- لا حالاتِ إرشادٍ في القاعدة، فيُفتح هنا ملفٌّ من مخالفةٍ يدوّنها الموجّه. كلُّه داخل begin … rollback.
begin;

-- التحضير: طالبٌ ومخالفةٌ كما في فحص ٣
with s as (
  select e.student_id, e.year_id, case when e.stage='primary' then 'primary' else 'intermediate_secondary' end scope
  from v2.enrolments e where e.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992' and e.status='active'
  order by e.student_id limit 1),
p as (
  select pr.id from v2.conduct_problems pr, s
  where pr.stage_scope in (s.scope,'all') and pr.mode='onsite'
    and not exists (select 1 from v2.behavior_records r where r.student_id=s.student_id and r.problem_id=pr.id
                      and r.year_id=s.year_id and r.status<>'voided')
  order by pr.degree_no, pr.id limit 1)
select set_config('t.student',(select student_id::text from s),true),
       set_config('t.problem',(select id::text from p),true),
       set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);

set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
select set_config('t.rec', public.v2_record_behavior(current_setting('t.student')::uuid, current_setting('t.problem')::int, 'الفصل','فحص')->>'record_id', true);
reset role;

-- فتحُ الملفّ بصلاحيّة المالك (كما يفتحه الحارسُ عند الإحالة)
select set_config('t.case', v2.fn_open_counsel_case(current_setting('t.rec')::uuid)::text, true);

-- منفّذُ الخطوات: يجري كلَّ خطوةٍ بصلاحيّة الدور الحاليّ، ويحفظ «نفذ» أو «رُفض: …»
-- (يُعرَّف داخل كلّ do لأنّ الدوالَّ المؤقّتة لا تُستعمل هنا)

-- ① الموجّه
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; c text := current_setting('t.case'); begin
  for s in select * from (values
    (1, 'جلسةٌ قبل الدراسة',          format('select public.v2_session_add(%L,current_date,30::smallint,%L,%L,%L)::text', c,'نقاش','تحسّنٌ طفيف','التالي')),
    (2, 'تقريرٌ قبل الدراسة',          format('select public.v2_case_report(%L,%L,%L)::text', c,'رأي','توصية')),
    (3, 'دراسةٌ ناقصة',               format('select public.v2_case_write(%L,%L,%L,%L,%L)::text', c,'رأي الطالب','ملاحظ','','خطّة')),
    (4, 'دراسةٌ كاملة',               format('select (public.v2_case_write(%L,%L,%L,%L,%L) is not null)::text', c,'رأي الطالب','ملاحظ','عوامل','خطّة')),
    (5, 'تقريرٌ بلا جلسة',            format('select public.v2_case_report(%L,%L,%L)::text', c,'رأي','توصية')),
    (6, 'جلسةٌ بتاريخٍ قادم',          format('select public.v2_session_add(%L,current_date+1,30::smallint,%L,%L,%L)::text', c,'نقاش','تحسّنٌ طفيف','التالي')),
    (7, 'جلسةٌ باستجابةٍ خارج الأربع', format('select public.v2_session_add(%L,current_date,30::smallint,%L,%L,%L)::text', c,'نقاش','ممتاز','التالي')),
    (8, 'جلسةٌ صحيحة',                format('select public.v2_session_add(%L,current_date,30::smallint,%L,%L,%L)->>%L', c,'نقاش','تحسّنٌ طفيف','التالي','session')),
    (9, 'التقرير',                    format('select (public.v2_case_report(%L,%L,%L) is not null)::text', c,'رأي','توصية')),
    (10,'التقرير ثانيةً',             format('select public.v2_case_report(%L,%L,%L)::text', c,'رأي','توصية')),
    (11,'بطاقةُ الحالة',              format('select (public.v2_case_card(%L) is not null)::text', c)),
    (12,'لوحةُ المتابعة',             format('select (public.v2_counsel_board(%L,null) is not null)::text', current_setting('t.school')))
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الموجّه · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- ② المالك بصفة وكيل شؤون الطلاب في المدرسة نفسها
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; c text := current_setting('t.case'); begin
  for s in select * from (values
    (13,'بطاقةُ الحالة',   format('select (public.v2_case_card(%L) is not null)::text', c)),
    (14,'لوحةُ المتابعة',  format('select (public.v2_counsel_board(%L,null) is not null)::text', current_setting('t.school'))),
    (15,'كتابةُ الدراسة',  format('select public.v2_case_write(%L,%L,%L,%L,%L)::text', c,'أ','ب','ج','د')),
    (16,'قراءةُ الجدول مباشرةً', 'select count(*)::text from v2.counsel_cases')
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'المالك · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n as "#", current_setting('t.s'||n) as النتيجة from generate_series(1,16) n;

rollback;
