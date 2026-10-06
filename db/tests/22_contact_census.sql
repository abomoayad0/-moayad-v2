-- فحص ٢٢ · إثباتُ الاتّصال بوليّ الأمر وحصرُ السلوكيّات — بالنداءات التي ترسلها wakeel.js و mukallaf.js.
-- كلُّه داخل begin … rollback. الهويّات: مفرح (وكيل · wakeel_full) · سعيد (الموجّه · المكلَّف بالحصر). لا حساب ولا كلمةَ مرور، ولا حذف.
-- p_task يُرسل فارغًا كما ترسله الشاشة: v2_student_tasks لا يرجع نوعَ المهمّة.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '20s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.saeed',(select person_id::text from v2.app_users where id='52bc11f6-8e82-44cd-9f4d-e9bf43aee128'),true);
select set_config('t.a',(select e.student_id::text from v2.enrolments e where e.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid and e.status='active'
          and exists (select 1 from v2.guardians g where g.student_id=e.student_id)
          and not exists (select 1 from v2.behavior_census c where c.student_id=e.student_id)
          order by e.student_id limit 1),true);

-- ① مفرح
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'v2_me: wakeel · wakeel_full', null::text, $q$select coalesce(r->>'role_ar','—')||' · wakeel='||coalesce(r->'can'->>'wakeel','—')||' · wakeel_full='||coalesce(r->'can'->>'wakeel_full','—') from (select public.v2_me() r) z$q$),
    (2, 'سجلُّ الاتّصال قبلُ', null, $q$select jsonb_array_length(public.v2_contacts_of(current_setting('t.a')::uuid))::text$q$),
    (3, 'اتّصالٌ بوسيلةٍ خارج الأربع', null, $q$select public.v2_contact_log(current_setting('t.a')::uuid,null,'بريد','لم يردّ','اتّصلتُ',null,null)::text$q$),
    (4, 'اتّصالٌ بلا بيان', null, $q$select public.v2_contact_log(current_setting('t.a')::uuid,null,'هاتف','لم يردّ',null,null,null)::text$q$),
    (5, 'هاتف · لم يردّ', null, $q$select public.v2_contact_log(current_setting('t.a')::uuid,null,'هاتف','لم يردّ','اتّصلتُ مرّتين','',time '09:15')::text$q$),
    (6, 'هاتف · ردّ وعلم', null, $q$select public.v2_contact_log(current_setting('t.a')::uuid,null,'هاتف','ردّ وعلم','أُبلغ بالتأخّر','سأتابعه',null)::text$q$),
    (7, 'سجلُّ الاتّصال بعدُ', null, $q$select jsonb_array_length(r)||' · '||(select string_agg(k,',' order by k) from jsonb_object_keys(r->0) k)||' ‖ '||(r->0)::text from (select public.v2_contacts_of(current_setting('t.a')::uuid) r) z$q$),
    (8, 'يكلّف سعيدًا بالحصر ٥ أيّام', 'census', $q$select r->>'census' from (select public.v2_census_assign(current_setting('t.a')::uuid,null,current_setting('t.saeed')::uuid,5::smallint) r) z$q$),
    (9, 'يكلّفه ثانيةً والأوّلُ قائم', null, $q$select public.v2_census_assign(current_setting('t.a')::uuid,null,current_setting('t.saeed')::uuid,5::smallint)::text$q$),
    (10, 'مدّةُ ٤٠ يومًا', null, $q$select public.v2_census_assign(current_setting('t.a')::uuid,null,current_setting('t.saeed')::uuid,40::smallint)::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'مفرح · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- ② سعيد — المكلَّف
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (11, 'v2_me: wakeel · wakeel_full', $q$select coalesce(r->>'role_ar','—')||' · wakeel='||coalesce(r->'can'->>'wakeel','—')||' · wakeel_full='||coalesce(r->'can'->>'wakeel_full','—') from (select public.v2_me() r) z$q$),
    (12, 'ما كُلّفتُ بحصره', $q$select jsonb_array_length(r)||' · '||(select string_agg(k,',' order by k) from jsonb_object_keys(r->0) k)||' ‖ '||(r->0)::text from (select public.v2_my_census(current_setting('t.school')::uuid) r) z$q$),
    (13, 'يسلّم بلا مسبّبات', $q$select public.v2_census_file(current_setting('t.census')::uuid,'يشارك','يتأخّر',null,null)::text$q$),
    (14, 'يسلّم كاملًا', $q$select public.v2_census_file(current_setting('t.census')::uuid,'يشارك في الإذاعة','يتأخّر صباحًا','السهر',null)::text$q$),
    (15, 'ينظر في الحصر (وليس وكيلًا)', $q$select public.v2_census_review(current_setting('t.census')::uuid,true,null)::text$q$),
    (16, 'يثبت اتّصالًا (الموجّهُ يملكه)', $q$select public.v2_contact_log(current_setting('t.a')::uuid,null,'رسالة','لم يردّ','أرسلتُ رسالة',null,null)::text$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'سعيد · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- ③ مفرح — ينظر
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (17, 'حصرُ الطالب', $q$select jsonb_array_length(r)||' · '||(select string_agg(k,',' order by k) from jsonb_object_keys(r->0) k)||' ‖ state='||(r->0->>'state')||' · '||coalesce(r->0->>'positives','—')||' / '||coalesce(r->0->>'negatives','—')||' / '||coalesce(r->0->>'causes','—') from (select public.v2_census_of(current_setting('t.a')::uuid) r) z$q$),
    (18, 'يعيده بلا سبب', $q$select public.v2_census_review(current_setting('t.census')::uuid,false,null)::text$q$),
    (19, 'يعيده بسبب', $q$select public.v2_census_review(current_setting('t.census')::uuid,false,'اذكر المواقف')::text$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'مفرح · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- ④ سعيد — يرى المعادَ ويسلّمه ثانيةً
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (20, 'ما كُلّفتُ بحصره بعد الإعادة', $q$select coalesce((select (x->>'state')||' · '||coalesce(x->>'returned_why','—') from jsonb_array_elements(public.v2_my_census(current_setting('t.school')::uuid)) x where x->>'census'=current_setting('t.census')),'ليس فيه')$q$),
    (21, 'يسلّمه ثانيةً', $q$select public.v2_census_file(current_setting('t.census')::uuid,'يشارك في الإذاعة','يتأخّر صباحًا يومي الأحد والاثنين','السهر',null)::text$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'سعيد · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- ⑤ مفرح — يقبله
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (22, 'يقبله', $q$select public.v2_census_review(current_setting('t.census')::uuid,true,null)::text$q$),
    (23, 'حصرُ الطالب بعدُ', $q$select (r->0->>'state')||' · returned_why='||coalesce(r->0->>'returned_why','—') from (select public.v2_census_of(current_setting('t.a')::uuid) r) z$q$),
    (24, 'السجلُّ الزمنيّ بصفة guardian (ما يراه وليُّ الأمر)', $q$select coalesce((select string_agg((e->>'kind')||': '||(e->>'title'),' ‖ ') from jsonb_array_elements(public.v2_student_timeline(current_setting('t.a')::uuid,'guardian')->'events') e),'—')$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'مفرح · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", left(current_setting('t.s'||n),1200) as النتيجة from generate_series(1,24) n;
rollback;
