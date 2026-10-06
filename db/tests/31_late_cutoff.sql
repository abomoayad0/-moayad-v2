-- فحص ٣١ · حدُّ التأخّر — الطريقُ كما تسلكه wusul.js: قواعدُ اليوم · التحقّقُ قبل الحفظ · الحفظ · وبدلُه تسجيلُ الغياب بالاصطفاف.
-- كلُّه داخل begin … rollback، على الطفيل. الهويّة: مفرح وكيلًا لشؤون الطلاب. لا حسابَ يُمسّ ولا حذف.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '20s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true), set_config('t.d',current_date::text,true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  perform set_config('t.a',(select student_id::text from public.v2_day_list(current_setting('t.school')::uuid,current_setting('t.d')::date) where state='unrecorded' order by student_no limit 1),true);
  perform set_config('t.b',(select student_id::text from public.v2_day_list(current_setting('t.school')::uuid,current_setting('t.d')::date) where state='unrecorded' order by student_no offset 1 limit 1),true);
  for s in select * from (values
    (1, 'قواعدُ اليوم', $q$select (r - 'periods')::text||' ‖ حصص '||jsonb_array_length(r->'periods') from (select public.v2_day_rules(current_setting('t.school')::uuid) r) z$q$),
    (2, 'تحقّق ٠٦:٤٠', $q$select public.v2_arrival_check(current_setting('t.school')::uuid,time '06:40')::text$q$),
    (3, 'تحقّق ٠٧:٣٠', $q$select public.v2_arrival_check(current_setting('t.school')::uuid,time '07:30')::text$q$),
    (4, 'تحقّق ٠٩:٣٠', $q$select public.v2_arrival_check(current_setting('t.school')::uuid,time '09:30')::text$q$),
    (5, 'تحقّق ١٤:١٢', $q$select public.v2_arrival_check(current_setting('t.school')::uuid,time '14:12')::text$q$),
    (6, 'حفظُ وصول a ‏٠٧:٣٠', $q$select public.v2_record_arrival(current_setting('t.a')::uuid,current_setting('t.d')::date,time '07:30','enter_class',null,'فحص')::text$q$),
    (7, 'a بعده', $q$select state||' · late='||coalesce(minutes_late::text,'∅') from public.v2_day_list(current_setting('t.school')::uuid,current_setting('t.d')::date) where student_id=current_setting('t.a')::uuid$q$),
    (8, 'حفظُ وصول b ‏١٤:١٢', $q$select public.v2_record_arrival(current_setting('t.b')::uuid,current_setting('t.d')::date,time '14:12','enter_class',null,'فحص')::text$q$),
    (9, 'وبدلُه: b غائبٌ بالاصطفاف', $q$select public.v2_record_assembly(current_setting('t.b')::uuid,current_setting('t.d')::date,'not_arrived')::text$q$),
    (10, 'b بعده', $q$select state||' · '||coalesce(assembly_ar,'∅') from public.v2_day_list(current_setting('t.school')::uuid,current_setting('t.d')::date) where student_id=current_setting('t.b')::uuid$q$),
    (11, 'تحقّقٌ لمدرسةٍ ليست له', $q$select public.v2_arrival_check('00000000-0000-0000-0000-000000000000'::uuid,time '07:30')::text$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
select n::text as "#", left(current_setting('t.s'||n),700) as النتيجة from generate_series(1,11) n;
rollback;
