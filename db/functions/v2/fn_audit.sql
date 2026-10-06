-- v2.fn_audit()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 25530c2b4ceac9dcba8b3d127abe6e59
CREATE OR REPLACE FUNCTION v2.fn_audit()
 RETURNS TABLE("باب" text, "الفحص" text, "المتوقع" text, "الواقع" text, "الحكم" text, "التفصيل" text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
with c as (
-- ① المراجع
select 'المراجع' b,'عدد بطاقات الإجراءات' k,'60' e, count(*)::text a,
  case when count(*)=60 then 'سليم' else 'خلل' end s, null::text d from v2.proc_cards
union all
select 'المراجع','بطاقة ينقصها باب من الخمسة عشر','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, string_agg(code||' ('||n||')','، ')
from (select c.code, 15-count(v.*) n from v2.proc_cards c
      left join v2.card_values v on v.card_code=c.code group by c.code having count(v.*)<15) x
union all
select 'المراجع','بطاقة بلا خطوات','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, string_agg(code,'، ')
from (select c.code from v2.proc_cards c
      where not exists (select 1 from v2.card_steps s where s.card_code=c.code)) x
union all
select 'المراجع','صف مصفوفة يشير إلى خطوة غير موجودة','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, string_agg(card_code||'/'||step_no,'، ')
from (select m.card_code, m.step_no from v2.card_matrix m
      where not exists (select 1 from v2.card_steps s where s.card_code=m.card_code and s.step_no=m.step_no)) x
union all
select 'المراجع','بطاقة صفحاتها خارج نطاق الدليل (1–385)','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, string_agg(code,'، ')
from (select code from v2.proc_cards where page_from<1 or page_to>385 or page_to<page_from) x
union all
select 'المراجع','بطاقة بلا تاريخ إصدار','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select c.code from v2.proc_cards c where not exists
      (select 1 from v2.card_values v where v.card_code=c.code and v.door_key='issue_date' and v.presence='filled')) x

-- ② لائحة السلوك
union all
select 'لائحة السلوك','عدد المشكلات السلوكية','128', count(*)::text,
  case when count(*)=128 then 'سليم' else 'انتبه' end, null from v2.conduct_problems
union all
select 'لائحة السلوك','عدد الإجراءات التربوية','49', count(*)::text,
  case when count(*)=49 then 'سليم' else 'انتبه' end, null from v2.conduct_actions
union all
select 'لائحة السلوك','إجراء تربوي بلا بنود مفكَّكة','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, string_agg(id::text,'، ')
from (select a.id from v2.conduct_actions a
      where not exists (select 1 from v2.conduct_action_items i where i.action_id=a.id)) x
union all
select 'لائحة السلوك','بند يرث خطوة غير موجودة','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select i.id from v2.conduct_action_items i join v2.conduct_actions a on a.id=i.action_id
      where i.inherits_step is not null and not exists (
        select 1 from v2.conduct_actions x where x.degree_no=a.degree_no and x.stage_scope=a.stage_scope
          and x.mode=a.mode and x.target=a.target and x.step_no=i.inherits_step)) x
union all
select 'لائحة السلوك','سلّم فيه قفزة في ترقيم الخطوات','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select degree_no,stage_scope,mode,target from v2.conduct_actions
      group by 1,2,3,4 having max(step_no)<>count(*)) x

-- ③ النماذج ونماذج الدرجات
union all
select 'النماذج','عدد النماذج الرسمية','21', count(*)::text,
  case when count(*)=21 then 'سليم' else 'انتبه' end, null from v2.official_forms
union all
select 'النماذج','نموذج بلا صفحة مصدر','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select form_no from v2.official_forms where btrim(coalesce(source_page,''))='') x
union all
select 'النماذج','نموذج تقويم مجموع درجاته ليس 100','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, string_agg(model_no::text,'، ')
from (select m.model_no from v2.grading_models m
      where m.model_no<>12 and (select sum((e->>'d')::int) from jsonb_array_elements(m.components) e) <> m.total) x
union all
select 'النماذج','مادة مرتبطة بنموذج غير موجود','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select s.id from v2.grading_subjects s
      where not exists (select 1 from v2.grading_models m where m.model_no=s.model_no)) x

-- ④ التقويم
union all
select 'التقويم','يوم مكرر في السنة الواحدة','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select year_id,on_g from v2.calendar_days group by 1,2 having count(*)>1) x
union all
select 'التقويم','يوم تاريخه الهجري لا يطابق جدول الشهور','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, string_agg(on_g::text,'، ')
from (select d.on_g from v2.calendar_days d where d.on_h <> v2.fn_to_hijri(d.on_g)) x
union all
select 'التقويم','يوم دراسة واقع في جمعة أو سبت','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select on_g from v2.calendar_days
      where day_kind in ('study','exam') and extract(dow from on_g) in (5,6)) x
union all
select 'التقويم','مدرسة بلا نطاق تقويم','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, string_agg(name_ar,'، ')
from (select name_ar from v2.schools where calendar_scope is null) x
union all
select 'التقويم','أسبوع حدوده مقلوبة أو خارج فصله','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select id from v2.calendar_weeks where to_g < from_g) x

-- ⑤ الطلاب
union all
select 'الطلاب','طالب بلا قيد فعّال','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, string_agg(full_name,'، ')
from (select s.full_name from v2.students s
      where not exists (select 1 from v2.enrolments e where e.student_id=s.id and e.status='active')) x
union all
select 'الطلاب','طالب له أكثر من قيد في السنة نفسها','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select student_id,year_id from v2.enrolments group by 1,2 having count(*)>1) x
union all
select 'الطلاب','طالب بلا ولي أمر','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, string_agg(full_name,'، ')
from (select s.full_name from v2.students s
      where not exists (select 1 from v2.guardians g where g.student_id=s.id)) x
union all
select 'الطلاب','الصف داخل رقم الطالب لا يطابق قيده','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, string_agg(student_no,'، ')
from (select s.student_no from v2.students s join v2.enrolments e on e.student_id=s.id
      where substr(s.student_no,5,2)::int <> e.grade) x
union all
select 'الطلاب','مرحلة القيد لا تطابق مرحلة المدرسة','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select e.id from v2.enrolments e join v2.schools sc on sc.id=e.school_id where e.stage<>sc.stage) x
union all
select 'الطلاب','رقم هوية مكرر بين طالبين','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, string_agg(national_id,'، ')
from (select national_id from v2.students where national_id is not null group by 1 having count(*)>1) x
union all
select 'الطلاب','طالب بلا تاريخ ميلاد','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'انتبه' end, string_agg(full_name,'، ')
from (select full_name from v2.students where birth_date is null) x

-- ⑥ اليوم الدراسي
union all
select 'اليوم الدراسي','رصد حضور في يوم ليس يوم دراسة','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, string_agg(on_date::text,'، ')
from (select a.on_date from v2.attendance a
      where v2.fn_day_kind(a.school_id,a.on_date) is distinct from 'study'
        and v2.fn_day_kind(a.school_id,a.on_date) is distinct from 'exam') x
union all
select 'اليوم الدراسي','رصد حصة في يوم ليس يوم دراسة','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select p.id from v2.period_attendance p
      where v2.fn_day_kind(p.school_id,p.on_date) not in ('study','exam')) x
union all
select 'اليوم الدراسي','طالب حالته متأخر وليس له إذن موافقة','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'انتبه' end, null
from (select a.id from v2.attendance a where a.state='late' and a.permit_id is null) x
union all
select 'اليوم الدراسي','طالب حالته متأخر بلا وقت وصول','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select id from v2.attendance where state='late' and arrived_at is null) x
union all
select 'اليوم الدراسي','يوم أُعيد فتحه بلا سبب مكتوب','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select id from v2.day_closures where reopened_at is not null and btrim(coalesce(reopen_reason,''))='') x
union all
select 'اليوم الدراسي','سجل يوم مقفَل وحالته ما زالت مبدئية','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select a.id from v2.attendance a join v2.day_closures c
      on c.school_id=a.school_id and c.on_date=a.on_date and c.reopened_at is null
      where a.day_status<>'closed') x
union all
select 'اليوم الدراسي','مدرسة بلا إعدادات يوم أو انصراف','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, string_agg(name_ar,'، ')
from (select s.name_ar from v2.schools s
      where not exists (select 1 from v2.day_settings d where d.school_id=s.id)
         or not exists (select 1 from v2.dismissal_settings d where d.school_id=s.id)) x
union all
select 'اليوم الدراسي','تأخر انصراف دون عتبة الحصر','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select d.id from v2.dismissal_records d join v2.dismissal_settings st on st.school_id=d.school_id
      where d.minutes_after < st.census_after_min) x

-- ⑦ المواظبة
union all
select 'المواظبة','رصيد مواظبة خارج النطاق 0–100','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select student_id from v2.attendance_ledger group by student_id,year_id
      having sum(points)<0 or sum(points)>100) x
union all
select 'المواظبة','حسم عن يوم ليس غياباً','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select l.id from v2.attendance_ledger l where l.kind='deduction' and l.on_date is not null
      and not exists (select 1 from v2.attendance a where a.student_id=l.student_id
                      and a.on_date=l.on_date and a.state='absent')) x
union all
select 'المواظبة','حسم عن يوم عذره مقبول ولم يُردّ','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select l.id from v2.attendance_ledger l
      where l.kind='deduction' and v2.fn_is_excused(l.student_id,l.on_date)
        and not exists (select 1 from v2.attendance_ledger r where r.student_id=l.student_id
                        and r.on_date=l.on_date and r.kind='restore')) x
union all
select 'المواظبة','طالب رُصد له غياب مقفَل وليس له رصيد افتتاحي','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select distinct a.student_id from v2.attendance a where a.state='absent' and a.day_status='closed'
      and not exists (select 1 from v2.attendance_ledger l where l.student_id=a.student_id and l.kind='opening')) x
union all
select 'المواظبة','حالة غياب عددها لا يطابق العدّاد','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select c.id from v2.absence_cases c
      where c.days_count > v2.fn_absence_days(c.student_id,c.year_id,c.excused)) x
union all
select 'المواظبة','مهمة غياب ساقطة بلا سبب','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select id from v2.absence_tasks where status='skipped' and btrim(coalesce(skip_reason,''))='') x
union all
select 'المواظبة','درجة من سلّم الغياب بلا بنود مفكَّكة','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select l.id from v2.absence_ladder l
      where not exists (select 1 from v2.absence_ladder_items i where i.ladder_id=l.id)) x

-- ⑧ الأعذار
union all
select 'الأعذار','عذر مردود بلا سبب مكتوب','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select id from v2.absence_excuse_claims where decision='rejected' and btrim(coalesce(decision_note,''))='') x
union all
select 'الأعذار','عذر تاريخه مقلوب','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select id from v2.absence_excuse_claims where to_date < from_date) x
union all
select 'الأعذار','عذر مقبول ولم يُردّ شيء من حسومه','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'انتبه' end, null
from (select c.id from v2.absence_excuse_claims c where c.decision='accepted'
      and exists (select 1 from v2.attendance_ledger l where l.student_id=c.student_id
                  and l.kind='deduction' and l.on_date between c.from_date and c.to_date)
      and not exists (select 1 from v2.attendance_ledger r where r.student_id=c.student_id
                  and r.kind='restore' and r.on_date between c.from_date and c.to_date)) x
union all
select 'الأعذار','استئذان بلا سبب مكتوب','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select id from v2.student_permissions where btrim(coalesce(reason_ar,''))='') x

-- ⑨ السلوك
union all
select 'السلوك','رصد إجراؤه لا يطابق درجته أو مرحلته','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select r.id from v2.behavior_records r
      join v2.conduct_problems p on p.id=r.problem_id
      join v2.conduct_actions a on a.id=r.action_id
      where a.degree_no<>p.degree_no or a.stage_scope<>p.stage_scope
         or a.mode<>p.mode or a.target<>p.target) x
union all
select 'السلوك','رصد بلا مهامّ مولَّدة','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select r.id from v2.behavior_records r
      where not exists (select 1 from v2.behavior_tasks t where t.record_id=r.id)) x
union all
select 'السلوك','مهمة ساقطة بلا سبب مكتوب','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select id from v2.behavior_tasks where status='skipped' and btrim(coalesce(skip_reason,''))='') x
union all
select 'السلوك','رصيد سلوك خارج النطاق 0–100','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select student_id from v2.behavior_ledger group by student_id,year_id,term_no
      having sum(points)<0 or sum(points)>100) x
union all
select 'السلوك','مضبوطات أُتلفت بغير لجنة التوجيه','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select id from v2.incident_seizures where destroyed and not destroyed_by_committee) x
union all
select 'السلوك','شاهد خارج صفوف المحضر السبعة','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select id from v2.incident_witnesses where ord<1 or ord>7) x
union all
select 'السلوك','حالة عنف نوعها غير معروف','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, null
from (select c.id from v2.violence_cases c
      where not exists (select 1 from v2.violence_types t where t.key=c.type_key)) x

-- ⑩ سجل النواقص والحرّاس
union all
select 'سجل النواقص','بند بلا نص إثبات','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, string_agg(gap_no::text,'، ')
from (select gap_no from v2.gaps where btrim(coalesce(established,''))='') x
union all
select 'سجل النواقص','بند مُسنَد أو محسوم بلا سند مكتوب','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, string_agg(gap_no::text,'، ')
from (select gap_no from v2.gaps where status in ('sourced','decided')
      and btrim(coalesce(closed_by,''))='') x
union all
select 'سجل النواقص','بند يشير إلى بطاقة غير موجودة','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, string_agg(gap_no::text,'، ')
from (select g.gap_no from v2.gaps g where g.card_code is not null
      and not exists (select 1 from v2.proc_cards c where c.code=g.card_code)) x
union all
select 'الحراس','جدول في v2 بلا حماية صفوف (RLS)','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, string_agg(relname,'، ')
from (select c.relname from pg_class c join pg_namespace n on n.oid=c.relnamespace
      where n.nspname='v2' and c.relkind='r' and not c.relrowsecurity) x
union all
select 'الحراس','جدول عليه RLS بلا سياسة واحدة','0', count(*)::text,
  case when count(*)=0 then 'سليم' else 'خلل' end, string_agg(relname,'، ')
from (select c.relname from pg_class c join pg_namespace n on n.oid=c.relnamespace
      where n.nspname='v2' and c.relkind='r' and c.relrowsecurity
        and not exists (select 1 from pg_policy p where p.polrelid=c.oid)) x
)
select b,k,e,a,s,d from c order by case s when 'خلل' then 0 when 'انتبه' then 1 else 2 end, b, k;
$function$
;
