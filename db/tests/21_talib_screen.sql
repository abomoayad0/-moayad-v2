-- فحص ٢١ · صفحةُ الطالب (viewS) على القاعدة — بمعاينة المنسوب (لا هويّةَ طالب، وحساباتُ الطلاب مغلقة).
-- قراءةٌ كلُّها، داخل begin … rollback.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '20s';
select set_config('t.a',(select e.student_id::text from v2.enrolments e where e.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid and e.status='active'
          order by e.student_id limit 1),true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', '7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'v2_me: can.student_card', $q$select coalesce(r->>'role_ar','—')||' · student_card='||coalesce(r->'can'->>'student_card','—') from (select public.v2_me() r) z$q$),
    (2, 'بطاقةُ الطالب: الاسم', $q$select coalesce(r->'student'->>'name','—')||' · '||(select string_agg(k,',' order by k) from jsonb_object_keys(r->'student') k) from (select public.v2_student_card(current_setting('t.a')::uuid) r) z$q$),
    (3, 'v2_opps_open_for: المفاتيح', $q$select (select string_agg(k,',' order by k) from jsonb_object_keys(r) k)||' ‖ score='||(r->'score')::text||' ‖ purpose='||coalesce(r->>'purpose','—')||' ‖ open '||jsonb_array_length(r->'open')||' · mine '||jsonb_array_length(r->'mine') from (select public.v2_opps_open_for(current_setting('t.a')::uuid) r) z$q$),
    (4, 'مفاتيحُ open و mine', $q$select coalesce((select string_agg(k,',' order by k) from jsonb_object_keys(r->'open'->0) k),'—')||' ‖ '||coalesce((select string_agg(k,',' order by k) from jsonb_object_keys(r->'mine'->0) k),'—') from (select public.v2_opps_open_for(current_setting('t.a')::uuid) r) z$q$),
    (5, 'السجلّ بصفة student (يطلبها منسوب)', $q$select (r->>'as_ar')||' · can_see='||(r->'can_see')::text||' · '||jsonb_array_length(r->'events') from (select public.v2_student_timeline(current_setting('t.a')::uuid,'student') r) z$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'مفرح · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
select n::text as "#", left(current_setting('t.s'||n),1400) as النتيجة from generate_series(1,5) n;
rollback;
