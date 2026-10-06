-- فحص ٣ · السلوك: الحسمُ وقفلُ الواقعة في اليوم الواحد وحدُّ المدرسة.
-- المدوِّن: سعيد (operator، مرشدٌ في مدرسة طُفيل). داخل begin … rollback.
begin;

-- التحضير بصلاحيّة المالك: طالبٌ فعّالٌ في طُفيل، ومخالفةٌ تنطبق على مرحلته ويحسم إجراؤها الأوّل،
-- ولم تُدوَّن عليه هذا العام. ومعه طالبٌ فعّالٌ في مالك لفحص حدّ المدرسة.
with s as (
  select e.student_id, e.year_id, case when e.stage='primary' then 'primary' else 'intermediate_secondary' end scope
  from v2.enrolments e where e.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992' and e.status='active'
  order by e.student_id limit 1),
p as (
  select pr.id, pr.degree_no from v2.conduct_problems pr, s
  where pr.stage_scope in (s.scope,'all') and pr.mode='onsite'
    and exists (select 1 from v2.conduct_actions a where a.degree_no=pr.degree_no and a.stage_scope=pr.stage_scope
                  and a.mode=pr.mode and a.target=pr.target and a.step_no=1 and a.deducts_points)
    and not exists (select 1 from v2.behavior_records r where r.student_id=s.student_id and r.problem_id=pr.id
                      and r.year_id=s.year_id and r.status<>'voided')
  order by pr.degree_no, pr.id limit 1)
select set_config('t.student',(select student_id::text from s),true),
       set_config('t.problem',(select id::text from p),true),
       set_config('t.expect',(select d.deduction::text from v2.conduct_degrees d, p where d.degree_no=p.degree_no),true),
       set_config('t.other',(select e.student_id::text from v2.enrolments e
          where e.school_id='f789f9ea-e474-49bc-86e0-3449258815f8' and e.status='active' order by e.student_id limit 1),true),
       set_config('t.before',(select count(*)::text from v2.behavior_ledger l, s where l.student_id=s.student_id and l.kind='deduction'),true);

set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';

-- الجلسةُ تُثبَّت هنا ولا يُعتمد على ما في v2.session_role، فـ my_school يقدّم مدرسةَ الجلسة.
select set_config('t.act', public.v2_act_as('counselor','7a847bb1-9b14-41ad-b9ba-7c8dee61a992'), true);

do $$ declare r jsonb; begin
  r := public.v2_record_behavior(current_setting('t.student')::uuid, current_setting('t.problem')::int, 'الفصل', 'فحص');
  perform set_config('t.rec', r->>'record_id', true);
  perform set_config('t.r1','نفذ · مهامّ: '||coalesce(jsonb_array_length(r->'tasks'),0),true);
exception when others then perform set_config('t.r1','رُفض: '||sqlerrm,true); end $$;

do $$ declare r jsonb; begin
  r := public.v2_record_behavior(current_setting('t.student')::uuid, current_setting('t.problem')::int, 'الفصل', 'فحص ثانٍ');
  perform set_config('t.r2','نفذ (خطأ: كان يجب القفل)',true);
exception when others then perform set_config('t.r2','رُفض: '||sqlerrm,true); end $$;

do $$ declare r jsonb; begin
  r := public.v2_record_behavior(current_setting('t.other')::uuid, current_setting('t.problem')::int, 'الفصل', 'فحص');
  perform set_config('t.r3','نفذ (خطأ: مدرسةٌ أخرى)',true);
exception when others then perform set_config('t.r3','رُفض: '||sqlerrm,true); end $$;

reset role;

select '٠ · الجلسة' as الفحص, current_setting('t.act') as النتيجة
union all select '١ · التدوين الأوّل', current_setting('t.r1')
union all select '٢ · الحسم في السجلّ',
  coalesce((select l.points::text from v2.behavior_ledger l where l.record_id=nullif(current_setting('t.rec',true),'')::uuid and l.kind='deduction'),'لا حسم')
  ||' · المتوقَّع -'||current_setting('t.expect')
union all select '٣ · الرصيد بعده',
  (select v2.fn_behavior_balance(r.student_id, r.year_id, r.term_no)::text from v2.behavior_records r where r.id=nullif(current_setting('t.rec',true),'')::uuid)
union all select '٤ · التدوين الثاني في اليوم نفسه', current_setting('t.r2')
union all select '٥ · طالبُ مدرسةٍ أخرى', current_setting('t.r3');

rollback;
