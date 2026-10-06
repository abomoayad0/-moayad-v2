-- فحص ١٩ · شاشةُ وليّ الأمر (viewG) على القاعدة — بهويّة وليّ الأمر وبالنداءات التي ترسلها walee.js.
-- قراءةٌ كلُّها، داخل begin … rollback. لا حساب ولا كلمةَ مرور.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '20s';
select set_config('t.other',(select e.student_id::text from v2.enrolments e where e.status='active' and e.student_id not in (select g.student_id from v2.guardians g where g.user_id='c62d924e-b3a5-4142-b06b-88836829addb') limit 1),true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"c62d924e-b3a5-4142-b06b-88836829addb","role":"authenticated"}';
do $$ declare s record; r text; kid text; begin
  kid := public.v2_guardian_me()->'children'->0->>'student_id';
  perform set_config('t.kid', coalesce(kid,''), true);
  for s in select * from (values
    (1, 'v2_me (ليس منسوبًا)', $q$select coalesce(public.v2_me()::text,'null')$q$),
    (2, 'v2_guardian_me', $q$select (r->>'name')||' · أبناء '||jsonb_array_length(r->'children')||' · '||(select string_agg(k,',' order by k) from jsonb_object_keys(r->'children'->0) k)||' ‖ '||(r->'children'->0)::text from (select public.v2_guardian_me() r) z$q$),
    (3, 'درجةُ الابن: v2_opps_open_for', $q$select (r->'score')::text||' · purpose='||coalesce(r->>'purpose','—')||' · open '||jsonb_array_length(r->'open')||' · mine '||jsonb_array_length(r->'mine') from (select public.v2_opps_open_for(current_setting('t.kid')::uuid) r) z$q$),
    (4, 'بطاقةُ الطالب: v2_student_card', $q$select left(public.v2_student_card(current_setting('t.kid')::uuid)::text,300)$q$),
    (5, 'السجلّ بصفة guardian', $q$select (r->>'as_ar')||' · '||jsonb_array_length(r->'events')||' · '||coalesce((select string_agg((e->>'kind')||': '||(e->>'title'),' ‖ ') from (select e from jsonb_array_elements(r->'events') e limit 8) q),'') from (select public.v2_student_timeline(current_setting('t.kid')::uuid,'guardian') r) z$q$),
    (6, 'السجلّ بصفة counselor (يطلبها ولا يملكها)', $q$select (r->>'as_ar')||' · '||jsonb_array_length(r->'events')||' · '||coalesce((select string_agg(distinct e->>'kind',',') from jsonb_array_elements(r->'events') e),'') from (select public.v2_student_timeline(current_setting('t.kid')::uuid,'counselor') r) z$q$),
    (7, 'v2_guardian_child', $q$select (select string_agg(k,',' order by k) from jsonb_object_keys(r) k)||' ‖ notices '||jsonb_array_length(r->'notices')||' · absences '||jsonb_array_length(r->'absences')||' ‖ '||(r->'student')::text from (select public.v2_guardian_child(current_setting('t.kid')::uuid) r) z$q$),
    (8, 'نماذج تنتظرك', $q$select count(*)||coalesce(' · '||(select string_agg(k,',' order by k) from jsonb_object_keys((select to_jsonb(f) from public.v2_guardian_forms() f limit 1)) k),'') from public.v2_guardian_forms()$q$),
    (9, 'أوّلُ نموذج', $q$select left((select to_jsonb(f)::text from public.v2_guardian_forms() f limit 1),900)$q$),
    (10, 'طالبٌ ليس ابنَه: السجلّ', $q$select public.v2_student_timeline(current_setting('t.other')::uuid,'guardian')::text$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'وليّ الأمر · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
select n::text as "#", left(current_setting('t.s'||n),1400) as النتيجة from generate_series(1,10) n
union all select 'أ', 'الابن: '||current_setting('t.kid');
rollback;
