-- فحص ٩ · ممارساتُ الصفّ: ١٢٧ مشتركةً لا تُمسّ، وفصلُ المدرسة نسختَها، وإعادتُها، والإخفاء،
-- والمجالات، والتصعيد، وحدُّ المدرسة والصفة. كلُّه داخل begin … rollback.
-- المعدِّل: مفرح بصفة وكيل شؤون الطلاب في طُفيل. والممنوع: سعيد بصفة الموجّه.
begin;

select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.shared',(select count(*)::text from v2.class_practices where school_id is null and active),true),
       set_config('t.c1',(select min(code) from v2.class_practices where school_id is null and active),true),
       set_config('t.scope',(select min(key) from v2.practice_scopes where school_id is null and active),true),
       set_config('t.prob',(select min(id)::text from v2.conduct_problems),true);
select set_config('t.c2',(select min(code) from v2.class_practices where school_id is null and active and code<>current_setting('t.c1')),true);

-- الموجّه
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'يضيف ممارسة', null::text, $q$select public.v2_practice_upsert('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,'فحص',1,'positive',current_setting('t.scope'),null,null,null,null,null,null,null,null,null)::text$q$)
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
    (2, 'النافذُ لمدرسته', null::text, $q$select jsonb_array_length(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null))||' نافذة · مفصولة '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'owned')::boolean)$q$),
    (3, 'يقرأ ممارساتِ مدرسةٍ أخرى', null::text, $q$select jsonb_array_length(public.v2_practices('f789f9ea-e474-49bc-86e0-3449258815f8',null,null))::text$q$),
    (4, 'المجالاتُ النافذة', null::text, $q$select jsonb_array_length(public.v2_practice_scopes('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'))||' · منها مشتركة '||(select count(*) from jsonb_array_elements(public.v2_practice_scopes('7a847bb1-9b14-41ad-b9ba-7c8dee61a992')) e where not (e->>'owned')::boolean)$q$),
    (5, 'يعدّل مشتركةً (c1)', 'fork', $q$select public.v2_practice_upsert('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.c1'),'نصٌّ لمدرستي',1,'positive',current_setting('t.scope'),null,null,null,null,null,null,null,null,null)->>'code'$q$),
    (6, 'وضعُ ذلك التعديل', null::text, $q$select public.v2_practice_upsert('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.fork'),'نصٌّ لمدرستي',1,'positive',current_setting('t.scope'),null,null,null,null,null,null,null,null,null)->>'mode'$q$),
    (7, 'بعد الفصل', null::text, $q$select jsonb_array_length(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null))||' نافذة · مفصولة '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'owned')::boolean)||' · الأصلُ ظاهر: '||exists(select 1 from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where e->>'code'=current_setting('t.c1'))||' · النسخةُ ظاهرة: '||exists(select 1 from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where e->>'code'=current_setting('t.fork'))$q$),
    (8, 'يضيف ممارسةً جديدة', 'new', $q$select public.v2_practice_upsert('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,'ممارسةُ مدرستي',1,'positive',current_setting('t.scope'),null,null,null,null,null,null,null,null,null)->>'code'$q$),
    (9, 'بعد الإضافة', null::text, $q$select jsonb_array_length(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null))||' نافذة · مفصولة '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'owned')::boolean)$q$),
    (10, 'يصعّد إلى مخالفةٍ غيرِ موجودة', null::text, $q$select public.v2_practice_upsert('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.fork'),'نصٌّ لمدرستي',1,'positive',current_setting('t.scope'),null,null,null,null,null,999999,null,null,null)::text$q$),
    (11, 'يصعّد إلى مخالفةٍ موجودة', null::text, $q$select public.v2_practice_upsert('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.fork'),'نصٌّ لمدرستي',1,'positive',current_setting('t.scope'),null,null,null,null,null,current_setting('t.prob')::int,null,null,null)->>'mode'$q$),
    (12, 'ممارسةٌ في مجالٍ غيرِ معروف', null::text, $q$select public.v2_practice_upsert('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,'x',1,'positive','لا_مجال',null,null,null,null,null,null,null,null,null)::text$q$),
    (13, 'يعدّل مجالًا مشتركًا', null::text, $q$select public.v2_scope_upsert('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.scope'),'اسمٌ آخر',null,null)::text$q$),
    (14, 'يضيف مجالًا لمدرسته', null::text, $q$select public.v2_scope_upsert('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,'مجالُ مدرستي',null,null)->>'ok'$q$),
    (15, 'المجالاتُ بعدها', null::text, $q$select jsonb_array_length(public.v2_practice_scopes('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'))::text$q$),
    (16, 'يعيد المفصولةَ للمشترك', null::text, $q$select public.v2_practice_unfork('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.fork'))::text$q$),
    (17, 'بعد الإعادة', null::text, $q$select jsonb_array_length(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null))||' نافذة · مفصولة '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'owned')::boolean)||' · الأصلُ ظاهر: '||exists(select 1 from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where e->>'code'=current_setting('t.c1'))||' · النسخةُ ظاهرة: '||exists(select 1 from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where e->>'code'=current_setting('t.fork'))$q$),
    (18, 'يعيد ممارسةً أنشأتها مدرستُه', null::text, $q$select public.v2_practice_unfork('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.new'))::text$q$),
    (19, 'يُخفي مشتركةً (c2)', null::text, $q$select public.v2_practice_toggle('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.c2'),false)::text$q$),
    (20, 'بعد إخفاء المشتركة', null::text, $q$select jsonb_array_length(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null))||' نافذة · مفصولة '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'owned')::boolean)||' · c2 ظاهرة: '||exists(select 1 from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where e->>'code'=current_setting('t.c2'))$q$),
    (21, 'يُخفي ممارسةَ مدرسته', null::text, $q$select public.v2_practice_toggle('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.new'),false)::text$q$),
    (22, 'بعد إخفاء ممارسة المدرسة', null::text, $q$select jsonb_array_length(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null))||' نافذة · مفصولة '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'owned')::boolean)||' · الجديدةُ ظاهرة: '||exists(select 1 from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where e->>'code'=current_setting('t.new'))$q$),
    (23, 'يحذف ممارسةً مباشرة', null::text, $q$delete from v2.class_practices where code=current_setting('t.c1') returning code$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الوكيل · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", current_setting('t.s'||n) as النتيجة from generate_series(1,23) n
union all select 'أ', 'المشتركةُ النافذة في القاعدة: '||current_setting('t.shared')||' · c1='||current_setting('t.c1')||' · c2='||current_setting('t.c2')
union all select 'ب', 'صفوفُ c2 في الجدول: '||(select string_agg(coalesce(school_id::text,'مشترك')||' active='||active, ' | ') from v2.class_practices where code=current_setting('t.c2') or based_on=current_setting('t.c2'));

rollback;
