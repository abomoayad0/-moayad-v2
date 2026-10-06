-- فحص ٩ · ممارساتُ الصفّ في المعمار الجديد: الأصلُ المشتركُ بكوده، والمدرسةُ تضع عليه سطرَ تعديلٍ أو إخفاء.
-- يُثبت: ١٢٧ ⇒ تعديلٌ ١٢٧ ⇒ إخفاءٌ ١٢٦ ⇒ إعادةٌ للأصل ١٢٧، والكودُ واحدٌ أبدًا. كلُّه داخل begin … rollback.
-- المعدِّل: مفرح بصفة وكيل شؤون الطلاب في طُفيل. والممنوع: سعيد بصفة الموجّه.
begin;

select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.shared',(select count(*)::text from v2.class_practices where school_id is null and active),true),
       set_config('t.c1',(select min(code) from v2.class_practices where school_id is null and active),true),
       set_config('t.scope',(select min(key) from v2.practice_scopes where school_id is null and active),true),
       set_config('t.prob',(select min(id)::text from v2.conduct_problems),true);
select set_config('t.c2',(select min(code) from v2.class_practices where school_id is null and active and code<>current_setting('t.c1')),true),
       set_config('t.c1_title',(select title_ar from v2.class_practices where code=current_setting('t.c1')),true);

-- الموجّه
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'يضيف ممارسة', null::text, $q$select public.v2_practice_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,'فحص',1,'positive',current_setting('t.scope'),null,null,null,null,null,null,null,null,null)::text$q$)
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
    (2, 'البداية', null::text, $q$select jsonb_array_length(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null))||' نافذة · معدَّلة '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'edited')::boolean)||' · لمدرستك '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'mine')::boolean)||' · مخفيّة '||jsonb_array_length(public.v2_practices_hidden('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'))$q$),
    (3, 'يقرأ ممارساتِ مدرسةٍ أخرى', null::text, $q$select jsonb_array_length(public.v2_practices('f789f9ea-e474-49bc-86e0-3449258815f8',null,null))::text$q$),
    (4, 'يعدّل مشتركةً (c1)', null::text, $q$select public.v2_practice_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.c1'),'نصٌّ لمدرستي',1,'positive',current_setting('t.scope'),null,null,null,null,null,null,null,null,null)::text$q$),
    (5, 'بعد التعديل', null::text, $q$select jsonb_array_length(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null))||' نافذة · معدَّلة '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'edited')::boolean)||' · لمدرستك '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'mine')::boolean)||' · مخفيّة '||jsonb_array_length(public.v2_practices_hidden('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'))||' · نصُّ c1: '||(select e->>'title' from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where e->>'code'=current_setting('t.c1'))$q$),
    (6, 'يُخفي c1 المعدَّلة', null::text, $q$select public.v2_practice_state('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.c1'),'أخفِ')->>'state'$q$),
    (7, 'بعد الإخفاء', null::text, $q$select jsonb_array_length(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null))||' نافذة · معدَّلة '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'edited')::boolean)||' · لمدرستك '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'mine')::boolean)||' · مخفيّة '||jsonb_array_length(public.v2_practices_hidden('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'))||' · c1 ظاهرة: '||exists(select 1 from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where e->>'code'=current_setting('t.c1'))||' · في المخفيّ: '||exists(select 1 from jsonb_array_elements(public.v2_practices_hidden('7a847bb1-9b14-41ad-b9ba-7c8dee61a992')) e where e->>'code'=current_setting('t.c1'))$q$),
    (8, 'يُظهر c1', null::text, $q$select public.v2_practice_state('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.c1'),'أظهِر')->>'state'$q$),
    (9, 'بعد الإظهار', null::text, $q$select jsonb_array_length(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null))||' نافذة · معدَّلة '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'edited')::boolean)||' · لمدرستك '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'mine')::boolean)||' · مخفيّة '||jsonb_array_length(public.v2_practices_hidden('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'))||' · نصُّ c1: '||(select e->>'title' from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where e->>'code'=current_setting('t.c1'))$q$),
    (10, 'يعيد c1 للأصل', null::text, $q$select public.v2_practice_state('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.c1'),'أعدها للأصل')->>'state'$q$),
    (11, 'بعد الإعادة', null::text, $q$select jsonb_array_length(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null))||' نافذة · معدَّلة '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'edited')::boolean)||' · لمدرستك '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'mine')::boolean)||' · مخفيّة '||jsonb_array_length(public.v2_practices_hidden('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'))||' · نصُّ c1 هو الأصل: '||((select e->>'title' from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where e->>'code'=current_setting('t.c1'))=current_setting('t.c1_title'))$q$),
    (12, 'يُخفي مشتركةً لم تُعدَّل (c2)', null::text, $q$select public.v2_practice_state('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.c2'),'أخفِ')->>'state'$q$),
    (13, 'بعد إخفاء c2', null::text, $q$select jsonb_array_length(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null))||' نافذة · معدَّلة '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'edited')::boolean)||' · لمدرستك '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'mine')::boolean)||' · مخفيّة '||jsonb_array_length(public.v2_practices_hidden('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'))||' · c2 ظاهرة: '||exists(select 1 from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where e->>'code'=current_setting('t.c2'))$q$),
    (14, 'يُظهر c2', null::text, $q$select public.v2_practice_state('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.c2'),'أظهِر')->>'state'$q$),
    (15, 'يضيف ممارسةً لمدرسته', 'new', $q$select public.v2_practice_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,'ممارسةُ مدرستي',1,'positive',current_setting('t.scope'),null,null,null,null,null,null,null,null,null)->>'code'$q$),
    (16, 'يعدّل ممارسةَ مدرسته', null::text, $q$select public.v2_practice_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.new'),'ممارسةُ مدرستي ٢',1,'positive',current_setting('t.scope'),null,null,null,null,null,null,null,null,null)->>'mode'$q$),
    (17, 'يعيد ممارسةَ مدرسته للأصل', null::text, $q$select public.v2_practice_state('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.new'),'أعدها للأصل')::text$q$),
    (18, 'بعد الإضافة', null::text, $q$select jsonb_array_length(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null))||' نافذة · معدَّلة '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'edited')::boolean)||' · لمدرستك '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'mine')::boolean)||' · مخفيّة '||jsonb_array_length(public.v2_practices_hidden('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'))$q$),
    (19, 'يُخفي ممارسةَ مدرسته', null::text, $q$select public.v2_practice_state('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.new'),'أخفِ')->>'state'$q$),
    (20, 'بعد إخفائها', null::text, $q$select jsonb_array_length(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null))||' نافذة · معدَّلة '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'edited')::boolean)||' · لمدرستك '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'mine')::boolean)||' · مخفيّة '||jsonb_array_length(public.v2_practices_hidden('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'))||' · ظاهرة: '||exists(select 1 from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where e->>'code'=current_setting('t.new'))||' · في المخفيّ: '||exists(select 1 from jsonb_array_elements(public.v2_practices_hidden('7a847bb1-9b14-41ad-b9ba-7c8dee61a992')) e where e->>'code'=current_setting('t.new'))$q$),
    (21, 'يُظهر ممارسةَ مدرسته', null::text, $q$select public.v2_practice_state('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.new'),'أظهِر')->>'state'$q$),
    (22, 'بعد إظهارها', null::text, $q$select jsonb_array_length(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null))||' نافذة · معدَّلة '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'edited')::boolean)||' · لمدرستك '||(select count(*) from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where (e->>'mine')::boolean)||' · مخفيّة '||jsonb_array_length(public.v2_practices_hidden('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'))||' · ظاهرة: '||exists(select 1 from jsonb_array_elements(public.v2_practices('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,null)) e where e->>'code'=current_setting('t.new'))$q$),
    (23, 'يصعّد c1 إلى مخالفةٍ غيرِ موجودة', null::text, $q$select public.v2_practice_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.c1'),'نصٌّ',1,'positive',current_setting('t.scope'),null,null,null,null,null,999999,null,null,null)::text$q$),
    (24, 'يصعّد c1 إلى مخالفةٍ موجودة', null::text, $q$select public.v2_practice_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.c1'),'نصٌّ',1,'positive',current_setting('t.scope'),null,null,null,null,null,current_setting('t.prob')::int,null,null,null)->>'mode'$q$),
    (25, 'ممارسةٌ في مجالٍ غيرِ معروف', null::text, $q$select public.v2_practice_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',null,'x',1,'positive','لا_مجال',null,null,null,null,null,null,null,null,null)::text$q$),
    (26, 'حالٌ غيرُ معروفة', null::text, $q$select public.v2_practice_state('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.c1'),'احذف')::text$q$),
    (27, 'يحذف ممارسةً مباشرة', null::text, $q$delete from v2.class_practices where code=current_setting('t.c1') returning code$q$),
    (28, 'ينادي الجسرَ المحذوف v2_practice_upsert', null::text, $q$select public.v2_practice_upsert('7a847bb1-9b14-41ad-b9ba-7c8dee61a992',current_setting('t.c1'),'x',1,'positive',current_setting('t.scope'),null,null,null,null,null,null,null,null,null)::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الوكيل · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", current_setting('t.s'||n) as النتيجة from generate_series(1,28) n
union all select 'أ', 'المشتركةُ النافذة في القاعدة: '||current_setting('t.shared')||' · c1='||current_setting('t.c1')||' · c2='||current_setting('t.c2')
union all select 'ب', 'الكودُ واحد: صفوفُ class_practices التي نصُّها مشتقٌّ من c1 أو أصلُها c1 = '||
  (select count(*) from v2.class_practices where code=current_setting('t.c1') or title_ar='نصٌّ لمدرستي' or title_ar='نصٌّ')||
  ' · وسطورُ التعديل لـ c1 = '||(select count(*) from v2.practice_overrides where code=current_setting('t.c1'));

rollback;
