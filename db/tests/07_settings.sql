-- فحص ٧ · الإعدادات: الصفةُ، والمقفَل، وذو الجسر الخاصّ (منعُ رفع الصلاحية)، والأعمدةُ المسموحة،
-- والرقميّ، والتصعيد (escalate_to)، وحدُّ المدرسة في الكتابة والقراءة. كلُّه داخل begin … rollback.
-- المعدِّل: مفرح بصفة وكيل شؤون الطلاب في طُفيل. والممنوع: سعيد بصفة الموجّه.
begin;

select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.code',(select min(code) from v2.class_practices),true),
       set_config('t.prob',(select min(id)::text from v2.conduct_problems),true),
       set_config('t.uid','11be0946-ff39-4eb7-8a74-023b580479be',true),
       set_config('t.cs_all',(select count(*)::text||' في '||count(distinct school_id)||' مدارس' from v2.class_sections),true),
       set_config('t.cs_mine',(select count(*)::text from v2.class_sections where school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'),true);

-- الموجّه
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'يعدّل إعدادًا', null::text, $q$select public.v2_setting_update('day_settings','7a847bb1-9b14-41ad-b9ba-7c8dee61a992','{"period_minutes":"45"}')::text$q$)
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
    (2, 'يعدّل جدولًا مقفلًا (المخالفات)', null::text, $q$select public.v2_setting_update('conduct_problems',current_setting('t.prob'),'{"text_ar":"x"}')::text$q$),
    (3, 'يرفع صلاحيّةً عبر الإعدادات', null::text, $q$select public.v2_setting_update('app_users',current_setting('t.uid'),'{"role":"owner"}')::text$q$),
    (4, 'يعدّل عمودًا غيرَ مسموح (المفتاح)', null::text, $q$select public.v2_setting_update('class_practices',current_setting('t.code'),'{"code":"x"}')::text$q$),
    (5, 'يضع نصًّا في حقلٍ رقميّ', null::text, $q$select public.v2_setting_update('class_practices',current_setting('t.code'),'{"points":"abc"}')::text$q$),
    (6, 'يضع رقمًا في حقلٍ رقميّ', null::text, $q$select public.v2_setting_update('class_practices',current_setting('t.code'),'{"points":"1.5"}')->>'ok'$q$),
    (7, 'يصعّد إلى مخالفةٍ غيرِ موجودة', null::text, $q$select public.v2_setting_update('class_practices',current_setting('t.code'),'{"escalate_to":"999999"}')::text$q$),
    (8, 'يصعّد إلى مخالفةٍ موجودة', null::text, $q$select public.v2_setting_update('class_practices',current_setting('t.code'),jsonb_build_object('escalate_to',current_setting('t.prob')))->>'ok'$q$),
    (9, 'يعدّل إعدادَ مدرسةٍ أخرى', null::text, $q$select public.v2_setting_update('day_settings','f789f9ea-e474-49bc-86e0-3449258815f8','{"period_minutes":"45"}')::text$q$),
    (10, 'يعدّل إعدادَ مدرسته', null::text, $q$select public.v2_setting_update('day_settings','7a847bb1-9b14-41ad-b9ba-7c8dee61a992','{"period_minutes":"45"}')->>'ok'$q$),
    (11, 'يقرأ صفوفَ مدرسته', null::text, $q$select jsonb_array_length(public.v2_setting_rows('class_sections','7a847bb1-9b14-41ad-b9ba-7c8dee61a992')->'rows')::text$q$),
    (12, 'يقرأ صفوفَ مدرسةٍ أخرى', null::text, $q$select jsonb_array_length(public.v2_setting_rows('class_sections','f789f9ea-e474-49bc-86e0-3449258815f8')->'rows')::text$q$),
    (13, 'يقرأ بلا مدرسة (null)', null::text, $q$select jsonb_array_length(public.v2_setting_rows('class_sections',null)->'rows')::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الوكيل · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", current_setting('t.s'||n) as النتيجة from generate_series(1,13) n
union all select 'أ', 'class_sections في القاعدة: '||current_setting('t.cs_all')||' · منها لطُفيل '||current_setting('t.cs_mine')
union all select 'ب', 'بعد التعديل: '||(select 'points='||points||' · escalate_to='||coalesce(escalate_to::text,'—') from v2.class_practices where code=current_setting('t.code'))
union all select 'ج', 'day_settings طُفيل: period_minutes='||(select period_minutes::text from v2.day_settings where school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992');

rollback;
