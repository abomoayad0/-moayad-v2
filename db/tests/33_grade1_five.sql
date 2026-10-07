-- فحص ٣٣ · الدرجةُ الأولى بمراحلها الخمس: المرجع · السلّم الآليّ · الحصر بطريقيه · الاتّصال والرسالة · الإجراء الرابع
-- يجري داخل begin … rollback فلا يبقى منه شيء. الطالب: حسام (الطفيل) · السلوك ٤٣ «النوم داخل الفصل» · وليّ الأمر: بندر
-- التهيئةُ الوحيدة خارج الجسور: قراءةُ أرقام المهامّ بلا RLS، ومحاولةُ إدخال خطّةٍ بحالة final (#٢٧)
begin;
set local lock_timeout = '5s';
set local statement_timeout = '30s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
select set_config('t.stu','04335119-5a39-45ad-ac13-4c1988c3034a',true);
select set_config('t.kid','d4c11fbb-c7d1-4242-954b-519d96aaa9b3',true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  perform set_config('t.me',(select v2.current_person())::text,true);
  perform set_config('t.neg',(select array_agg(x->>'id' order by (x->>'ord')::int)::text from (select x from jsonb_array_elements(public.v2_census_list(current_setting('t.school')::uuid)->'negative') x limit 2) z),true);
  perform set_config('t.pos',(select array_agg(x->>'id')::text from (select x from jsonb_array_elements(public.v2_census_list(current_setting('t.school')::uuid)->'positive') x limit 1) z),true);
  for s in select * from (values
    (1, '① قوائم الحصر', null, $q$select 'سلبيّ '||jsonb_array_length(r->'negative')||' · إيجابيّ '||jsonb_array_length(r->'positive')||' · أوّلها '||(r->'negative'->0->>'icon')||' '||(r->'negative'->0->>'text')||' — '||coalesce(r->'negative'->0->>'hint','∅')||' · mine '||(r->'negative'->0->>'mine') from (select public.v2_census_list(current_setting('t.school')::uuid) r) z$q$),
    (2, '① بنكُ cause للسلوك ٤٣', null, $q$select jsonb_array_length(r)||' عبارة · أوّلها: '||(r->0->>'text') from (select public.v2_bank('cause',43,current_setting('t.school')::uuid) r) z$q$),
    (3, '① بنكُ limit عامّ', null, $q$select jsonb_array_length(public.v2_bank('limit',null,current_setting('t.school')::uuid))::text$q$),
    (4, '① النصيحة ٤٣ للرصدة ١ و٥', null, $q$select (public.v2_advice_for(43,1::smallint)->>'text')||' ‖ ٥⇐ '||(public.v2_advice_for(43,5::smallint))::text$q$),
    (5, '② الرصدة ١ (٤٣ ح١)', null, $q$select (set_config('t.r1', r->>'record', true) is not null)::text||' '||'الرصدة '||(r->>'occurrence_ar')||' · الإجراء '||coalesce(r->>'step_ar',r->>'step','?')||' ‖ auto '||(r->'auto')::text||' ‖ advice '||coalesce(r->>'advice','∅') from (select public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,1::smallint) r) z$q$),
    (6, '② الرصدة ٢ (٤٣ ح٢)', null, $q$select (set_config('t.r2', r->>'record', true) is not null)::text||' '||'الرصدة '||(r->>'occurrence_ar')||' · الإجراء '||coalesce(r->>'step_ar',r->>'step','?')||' ‖ auto '||(r->'auto')::text||' ‖ advice '||coalesce(r->>'advice','∅') from (select public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,2::smallint) r) z$q$),
    (7, '② الرصدة ٣ (٤٣ ح٣)', null, $q$select (set_config('t.r3', r->>'record', true) is not null)::text||' '||'الرصدة '||(r->>'occurrence_ar')||' · الإجراء '||coalesce(r->>'step_ar',r->>'step','?')||' ‖ auto '||(r->'auto')::text||' ‖ advice '||coalesce(r->>'advice','∅') from (select public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,3::smallint) r) z$q$),
    (8, '② الرصدة ٤ (٤٣ ح٤)', null, $q$select (set_config('t.r4', r->>'record', true) is not null)::text||' '||'الرصدة '||(r->>'occurrence_ar')||' · الإجراء '||coalesce(r->>'step_ar',r->>'step','?')||' ‖ auto '||(r->'auto')::text||' ‖ advice '||coalesce(r->>'advice','∅') from (select public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,4::smallint) r) z$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, coalesce(r,''), true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
-- أرقامُ المهامّ تُقرأ بلا RLS (تهيئةٌ للفحص لا جسر)
reset role;
do $$ begin
  perform set_config('t.f2',(select id::text from v2.behavior_tasks where record_id::text=current_setting('t.r2') and kind='follow_up'),true);
  perform set_config('t.n3',(select id::text from v2.behavior_tasks where record_id::text=current_setting('t.r3') and kind='notify_guardian'),true);
  perform set_config('t.s9','② ما بقي مفتوحًا لكلّ إجراء ⇐ '||(select string_agg('الإجراء '||br.step_no||': '||(select count(*) from v2.behavior_tasks t where t.record_id=br.id and t.status='open')||' مفتوح ['||coalesce((select string_agg(t.kind,',') from v2.behavior_tasks t where t.record_id=br.id and t.status='open'),'')||']',' · ' order by br.occurrence_no) from v2.behavior_records br where br.id::text in (current_setting('t.r1'),current_setting('t.r2'),current_setting('t.r3'),current_setting('t.r4'))),true);
end $$;
set local role authenticated;
do $$ declare s record; r text; begin
  for s in select * from (values
    (10, '③ حصرٌ بلا سلبيّ', null, $q$select public.v2_census_self(current_setting('t.stu')::uuid,null,'{}'::uuid[],null,'سبب','')::text$q$),
    (11, '③ حصرٌ بلا مسبّبات', null, $q$select public.v2_census_self(current_setting('t.stu')::uuid,null,current_setting('t.neg')::uuid[],null,' ','')::text$q$),
    (12, '③ «أحصرُ بنفسي» عن مهمّة الرصدة ٢', null, $q$select public.v2_census_self(current_setting('t.stu')::uuid,current_setting('t.f2')::uuid,current_setting('t.neg')::uuid[],current_setting('t.pos')::uuid[],'سهرٌ متأخّر','يُتابَع')::text$q$),
    (13, '③ «أكلّف به أحدًا» (نفسي، ٣ أيّام)', 'cn', $q$select r->>'census' from (select public.v2_census_assign(current_setting('t.stu')::uuid,null,current_setting('t.me')::uuid,3::smallint) r) z$q$),
    (14, '③ تسليمُ المكلَّف بالقوائم', null, $q$select public.v2_census_file(current_setting('t.cn')::uuid,current_setting('t.neg')::uuid[],null,'ضيقُ الوقت',null)::text$q$),
    (15, '③ v2_census_of', null, $q$select string_agg((x->>'who')||' · '||(x->>'state')||' · '||coalesce(x->>'summary','∅')||' · '||(select string_agg((y->>'icon')||(y->>'text'),'،') from jsonb_array_elements(x->'neg') y),' ‖ ') from jsonb_array_elements(public.v2_census_of(current_setting('t.stu')::uuid)) x$q$),
    (16, '③ v2_census_sweep', null, $q$select public.v2_census_sweep(current_setting('t.school')::uuid)::text$q$),
    (17, '④ ردّ ورفض بلا قوله', null, $q$select public.v2_contact_log(current_setting('t.stu')::uuid,null,'هاتف','ردّ ورفض','دار كذا',null,null,null)::text$q$),
    (18, '④ لم يردّ بلا ساعة', null, $q$select public.v2_contact_log(current_setting('t.stu')::uuid,null,'هاتف','لم يردّ',null,null,null,null)::text$q$),
    (19, '④ الرقم خطأ بلا رقم', null, $q$select public.v2_contact_log(current_setting('t.stu')::uuid,null,'هاتف','الرقم خطأ',null,null,null,null)::text$q$),
    (20, '④ الرقم خطأ: «لا يُعرف»', null, $q$select public.v2_contact_log(current_setting('t.stu')::uuid,null,'هاتف','الرقم خطأ',null,null,null,'لا يُعرف')::text$q$),
    (21, '④ لم يردّ ١٠:١٥', null, $q$select public.v2_contact_log(current_setting('t.stu')::uuid,null,'هاتف','لم يردّ',null,null,time '10:15',null)::text$q$),
    (22, '④ ردّ وعلم عن مهمّة الرصدة ٣', null, $q$select public.v2_contact_log(current_setting('t.stu')::uuid,current_setting('t.n3')::uuid,'رسالة','ردّ وعلم','أُرسلت الرسالةُ وعلم',null,null,null)::text$q$),
    (23, '④ v2_guardian_message (الرصدة ٣)', null, $q$select 'step '||(r->>'step')||' · '||coalesce(r->>'guardian','∅')||' · '||coalesce(r->>'phone','∅')||' · '||coalesce(left(r->>'whatsapp',40),'∅')||' ‖ '||replace(left(r->>'body',420),E'\n',' ⏎ ') from (select public.v2_guardian_message(current_setting('t.r3')::uuid) r) z$q$),
    (24, '⑤ قياسُ الاستجابة بلا خطّة', null, $q$select public.v2_response_check(current_setting('t.r4')::uuid)::text$q$),
    (25, '⑤ الإحالةُ بلا خطّة', null, $q$select public.v2_refer_committee(current_setting('t.r4')::uuid,null,'لم يستجب','دراسةُ حاله')::text$q$),
    (26, '⑤ ردُّ وليّ الأمر من المدرسة', null, $q$select public.v2_guardian_reply(current_setting('t.stu')::uuid,null,'دعوة','أحضر',null,null)::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, coalesce(r,''), true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
-- ما رجع من الرصد نفسه (auto · advice)
reset role;
do $$ declare r text; begin
  -- الخطّةُ المعتمدة: تجربةُ إدخالها بحالة 'final' كما يقرؤها v2_response_check
  begin
    insert into v2.behavior_plans(record_id,student_id,status,school_id,final_at)
    values (current_setting('t.r4')::uuid,current_setting('t.stu')::uuid,'final',current_setting('t.school')::uuid,now());
    r := 'نفذ';
  exception when others then r := 'رُفض: '||sqlerrm; end;
  perform set_config('t.s27','⑤ تهيئة: خطّةٌ بحالة final (كما يقرؤها الفحص) ⇐ '||r,true);
end $$;
set local role authenticated;
do $$ declare s record; r text; begin
  for s in select * from (values
    (28, '⑤ قياسُ الاستجابة بعد التهيئة', $q$select public.v2_response_check(current_setting('t.r4')::uuid)::text$q$)
  ) v(n,l,q) loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
-- وليّ الأمر (بندر) من بوّابته
set local request.jwt.claims = '{"sub":"c62d924e-b3a5-4142-b06b-88836829addb","role":"authenticated"}';
do $$ declare s record; r text; begin
  for s in select * from (values
    (29, '① البنك لوليّ الأمر', $q$select public.v2_bank('cause',null,null)::text$q$),
    (30, '⑤ ردُّه: أعتذر بلا موعد', $q$select public.v2_guardian_reply(current_setting('t.kid')::uuid,null,'دعوة','أعتذر وأقترح موعدًا',null,null)::text$q$),
    (31, '⑤ ردُّه: لا أستطيع بلا سبب', $q$select public.v2_guardian_reply(current_setting('t.kid')::uuid,null,'دعوة','لا أستطيع',null,null)::text$q$),
    (32, '⑤ ردُّه: أعتذر ويقترح موعدًا', $q$select public.v2_guardian_reply(current_setting('t.kid')::uuid,null,'دعوة','أعتذر وأقترح موعدًا','عندي دوام',date '2026-10-12')::text$q$),
    (33, '② النصيحة لوليّ الأمر (v2_advice_for ٤٣/٢)', $q$select public.v2_advice_for(43,2::smallint)::text$q$)
  ) v(n,l,q) loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
select n::text as "#", left(current_setting('t.s'||n),1200) as النتيجة from generate_series(1,33) n
union all
select 'T'||br.occurrence_no, string_agg(t.kind||' '||t.status||coalesce(' «'||t.auto_note||'»','')||coalesce(' due '||t.due_on,''),' · ' order by t.ord)
 from v2.behavior_records br join v2.behavior_tasks t on t.record_id=br.id where br.id::text in (current_setting('t.r1',true),current_setting('t.r2',true),current_setting('t.r3',true),current_setting('t.r4',true)) group by br.occurrence_no;
rollback;
