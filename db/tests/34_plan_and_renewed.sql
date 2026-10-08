-- فحص ٣٤ · ما جُدّد: الاتّصالُ بلا «ما دار» · ترتيبُ البطاقة · رابطُ واتساب · الخطّة · v2_record_advice · v2_guardian_pending · v2_message_template · v2_problems · p_all · p_school
-- داخل begin … rollback. والجزءُ الثاني (بعد الفاصل) يهيّئ خطّةً بإدخالٍ مباشر لأنّ v2_plan_write معطّل
begin;
set local lock_timeout = '5s';
set local statement_timeout = '40s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
select set_config('t.stu','04335119-5a39-45ad-ac13-4c1988c3034a',true);
select set_config('t.kid','d4c11fbb-c7d1-4242-954b-519d96aaa9b3',true);
select set_config('t.pl','',true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'الرصدة ١', $q$select (set_config('t.r1', r->>'record', true) is not null)::text||' '||(r->>'occurrence_ar') from (select public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,1::smallint) r) z$q$),
    (2, 'الرصدة ٢', $q$select (set_config('t.r2', r->>'record', true) is not null)::text||' '||(r->>'occurrence_ar') from (select public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,2::smallint) r) z$q$),
    (3, 'الرصدة ٣ ⇐ auto', $q$select (set_config('t.r3', r->>'record', true) is not null)::text||' '||(r->'auto')::text from (select public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,3::smallint) r) z$q$),
    (4, 'الرصدة ٤ ⇐ auto', $q$select (set_config('t.r4', r->>'record', true) is not null)::text||' '||(r->'auto')::text from (select public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,4::smallint) r) z$q$),
    (5, 'ترتيبُ البطاقة (أوّلُ ثلاث)', $q$select string_agg((x->>'occurrence'),' · ') from (select x from jsonb_array_elements(public.v2_student_card(current_setting('t.stu')::uuid)->'behavior') x limit 3) z$q$),
    (6, 'لم يردّ ١٠:١٥', $q$select public.v2_contact_log(current_setting('t.stu')::uuid,null,'هاتف','لم يردّ',null,null,time '10:15',null)->>'note'$q$),
    (7, 'الرقم مغلق', $q$select public.v2_contact_log(current_setting('t.stu')::uuid,null,'هاتف','الرقم مغلق',null,null,null,null)->>'note'$q$),
    (8, 'الرقم خطأ «لا يُعرف»', $q$select public.v2_contact_log(current_setting('t.stu')::uuid,null,'هاتف','الرقم خطأ',null,null,null,'لا يُعرف')->>'note'$q$),
    (9, 'رابطُ واتساب', $q$select left(public.v2_guardian_message(current_setting('t.r3')::uuid)->>'whatsapp',90)$q$),
    (10, 'الخطّة بلا مستهدف', $q$select public.v2_plan_write(current_setting('t.stu')::uuid,current_setting('t.r4')::uuid,null,null,'ينام في الحصّة',null,null,null,null,null,null,'يُتابَع',null,null)::text$q$),
    (11, 'الخطّة مسودّة', $q$select (set_config('t.pl', r->>'plan', true) is not null)::text||' '||(r->>'note') from (select public.v2_plan_write(current_setting('t.stu')::uuid,current_setting('t.r4')::uuid,null,null,'ينام في الحصّة','يضع رأسه على الطاولة','السهر','يفوته الشرح','الراحة','تنبيهان وإشعار','يبقى منتبهًا طوال الحصّة',E'يُجلس في الأمام\nيُكلَّف بمهمّة في الحصّة\nيُتابَع نومُه مع وليّه',current_date,current_date+14) r) z$q$),
    (12, 'v2_plan_of', $q$select (r->0->>'state_ar')||' · needs_teacher '||(r->0->>'needs_teacher')||' · can_final '||(r->0->>'can_final') from (select public.v2_plan_of(current_setting('t.stu')::uuid) r) z$q$),
    (13, 'اعتمادٌ بلا رأي المعلّم', $q$select public.v2_plan_final(nullif(current_setting('t.pl'),'')::uuid,'أعتمد')::text$q$),
    (14, 'رأيُ وليّ الأمر من المدرسة', $q$select public.v2_plan_opinion(nullif(current_setting('t.pl'),'')::uuid,'guardian','موافق')::text$q$),
    (15, 'رأيُ معلّم الفصل', $q$select public.v2_plan_opinion(nullif(current_setting('t.pl'),'')::uuid,'teacher','ينعس في الحصّة الأولى')::text$q$),
    (16, 'اعتمادٌ بغير «أعتمد»', $q$select public.v2_plan_final(nullif(current_setting('t.pl'),'')::uuid,'نعم')::text$q$),
    (17, 'اعتمادٌ بـ«أعتمد»', $q$select public.v2_plan_final(nullif(current_setting('t.pl'),'')::uuid,'أعتمد')->>'note'$q$),
    (18, 'تعديلُ المعتمدة', $q$select public.v2_plan_write(current_setting('t.stu')::uuid,null,null,nullif(current_setting('t.pl'),'')::uuid,'x',null,null,null,null,null,'y','z',null,null)::text$q$),
    (19, 'القياسُ بلا رصدٍ بعدها', $q$select (r->>'state')||' · '||(r->>'state_ar')||' · can_refer '||(r->>'can_refer')||' · '||(r->>'by') from (select public.v2_response_check(current_setting('t.r4')::uuid) r) z$q$),
    (20, 'الإحالةُ و«تعدّل»', $q$select public.v2_refer_committee(current_setting('t.r4')::uuid,null,'لم يستجب','دراسةُ حاله')::text$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
-- الرصدُ بعد الاعتماد يجب أن يقع بعد final_at: تُقدَّم final_at دقيقةً (تهيئةٌ للفحص)
reset role;
update v2.behavior_plans set final_at = now() - interval '1 minute' where id::text = current_setting('t.pl');
-- دعوةٌ تنتظر ردَّ بندر (تهيئة)
insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,visible_to,needs_action,action_ar,is_test)
values (current_setting('t.school')::uuid,'other',current_date,current_setting('t.kid')::uuid,'دعوةٌ لمقابلة المدرسة — فحص','نرجو حضوركم','all',true,'أكّد حضورك',true)
returning (set_config('t.ev', id::text, true) is not null);
set local role authenticated;
do $$ declare s record; r text; begin
  for s in select * from (values
    (21, 'رصدةٌ بعد الاعتماد', $q$select (set_config('t.r5', r->>'record', true) is not null)::text||' '||(r->>'occurrence_ar') from (select public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,5::smallint) r) z$q$),
    (22, 'القياسُ بعدها', $q$select (r->>'state')||' · '||(r->>'state_ar')||' · قبل '||(r->>'pre_ar')||' · بعد '||(r->>'post_ar')||' · can_refer '||(r->>'can_refer') from (select public.v2_response_check(current_setting('t.r4')::uuid) r) z$q$),
    (23, 'الإحالة', $q$select (r->>'note')||' ‖ '||((r->'file') - 'response')::text from (select public.v2_refer_committee(current_setting('t.r4')::uuid,null,'لم يستجب بعد الخطّة','دراسةُ حاله') r) z$q$),
    (24, 'v2_record_advice (الرصدة ٢)', $q$select public.v2_record_advice(current_setting('t.r2')::uuid)::text$q$),
    (25, 'v2_message_template', $q$select (r->>'mine')||' · '||(r->'vars')::text||' · '||left(r->>'body',40) from (select public.v2_message_template(current_setting('t.school')::uuid,null) r) z$q$),
    (26, 'v2_problems(الدرجة ١)', $q$select jsonb_array_length(r)||' · '||(r->0->>'text')||' · advice_n '||(r->0->>'advice_n')||' · bank_n '||(r->0->>'bank_n') from (select public.v2_problems(current_setting('t.school')::uuid,1::smallint) r) z$q$),
    (27, 'v2_census_list بالموقوف', $q$select jsonb_array_length(r->'negative')||' · '||jsonb_array_length(r->'positive')||' · active '||(r->'negative'->0->>'active') from (select public.v2_census_list(current_setting('t.school')::uuid,true) r) z$q$),
    (28, 'v2_bank بالموقوف', $q$select jsonb_array_length(public.v2_bank('cause',null,current_setting('t.school')::uuid,true))::text$q$),
    (29, 'v2_advice_for بالمدرسة', $q$select public.v2_advice_for(43,2::smallint,current_setting('t.school')::uuid)::text$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
set local request.jwt.claims = '{"sub":"c62d924e-b3a5-4142-b06b-88836829addb","role":"authenticated"}';
do $$ declare s record; r text; begin
  for s in select * from (values
    (30, 'وليُّ الأمر: دعواتُه', $q$select string_agg((x->>'title')||' · replied '||(x->>'replied'),' ‖ ') from jsonb_array_elements(public.v2_guardian_pending(current_setting('t.kid')::uuid)) x where x->>'event'=current_setting('t.ev')$q$),
    (31, 'وليُّ الأمر: يردّ بالحدث', $q$select public.v2_guardian_reply(current_setting('t.kid')::uuid,current_setting('t.ev')::uuid,'دعوة','أحضر',null,null)->>'note'$q$),
    (32, 'وليُّ الأمر: دعواتُه بعد الردّ', $q$select string_agg('replied '||(x->>'replied')||' · '||coalesce(x->>'reply','∅'),' ‖ ') from jsonb_array_elements(public.v2_guardian_pending(current_setting('t.kid')::uuid)) x where x->>'event'=current_setting('t.ev')$q$),
    (33, 'وليُّ الأمر: نصيحةُ رصدةِ غيرِ ابنه', $q$select public.v2_record_advice(current_setting('t.r2')::uuid)::text$q$),
    (34, 'وليُّ الأمر: رأيُه في خطّةِ غيرِ ابنه', $q$select public.v2_plan_opinion(nullif(current_setting('t.pl'),'')::uuid,'guardian','موافق')::text$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
select n::text as "#", left(current_setting('t.s'||n),900) as النتيجة from generate_series(1,34) n;
rollback;

-- ════ الجزءُ الثاني: خطّةٌ مهيّأةٌ بإدخالٍ مباشر (steps مصفوفة) ثمّ الرأي والاعتماد والقياس والإحالة بالجسور ════
begin;
set local lock_timeout = '5s';
set local statement_timeout = '40s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
select set_config('t.stu','04335119-5a39-45ad-ac13-4c1988c3034a',true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'الرصدة ١', $q$select set_config('t.r1', public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,1::smallint)->>'record', true)$q$),
    (2, 'الرصدة ٢', $q$select set_config('t.r2', public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,2::smallint)->>'record', true)$q$),
    (3, 'الرصدة ٣', $q$select set_config('t.r3', public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,3::smallint)->>'record', true)$q$),
    (4, 'الرصدة ٤', $q$select set_config('t.r4', public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,4::smallint)->>'record', true)$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ';
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
insert into v2.behavior_plans(school_id,student_id,record_id,problem_desc,target_behavior,steps,status,is_test)
values (current_setting('t.school')::uuid,current_setting('t.stu')::uuid,current_setting('t.r4')::uuid,'ينام في الحصّة','يبقى منتبهًا',array['يُجلس في الأمام','يُكلَّف بمهمّة'],'draft',true)
returning (set_config('t.pl', id::text, true) is not null);
set local role authenticated;
do $$ declare s record; r text; begin
  for s in select * from (values
    (5, 'v2_plan_of', $q$select (r->0->>'state_ar')||' · needs_teacher '||(r->0->>'needs_teacher')||' · can_final '||(r->0->>'can_final')||' · steps '||(r->0->'steps')::text from (select public.v2_plan_of(current_setting('t.stu')::uuid) r) z$q$),
    (6, 'اعتمادٌ بلا رأي المعلّم', $q$select public.v2_plan_final(current_setting('t.pl')::uuid,'أعتمد')::text$q$),
    (7, 'رأيُ وليّ الأمر من المدرسة', $q$select public.v2_plan_opinion(current_setting('t.pl')::uuid,'guardian','موافق')::text$q$),
    (8, 'رأيُ معلّم الفصل', $q$select public.v2_plan_opinion(current_setting('t.pl')::uuid,'teacher','ينعس في الحصّة الأولى')::text$q$),
    (9, 'can_final بعده', $q$select (public.v2_plan_of(current_setting('t.stu')::uuid)->0->>'can_final')$q$),
    (10, 'اعتمادٌ بغير «أعتمد»', $q$select public.v2_plan_final(current_setting('t.pl')::uuid,'نعم')::text$q$),
    (11, 'اعتمادٌ بـ«أعتمد»', $q$select public.v2_plan_final(current_setting('t.pl')::uuid,'أعتمد')->>'note'$q$),
    (12, 'القياسُ بلا رصدٍ بعدها', $q$select (r->>'state')||' · '||coalesce(r->>'state_ar','∅')||' · can_refer '||(r->>'can_refer')||' · '||coalesce(r->>'by','∅')||' · '||coalesce(r->>'why','') from (select public.v2_response_check(current_setting('t.r4')::uuid) r) z$q$),
    (13, 'الإحالةُ و«تعدّل»', $q$select public.v2_refer_committee(current_setting('t.r4')::uuid,null,'لم يستجب','دراسةُ حاله')::text$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
update v2.behavior_plans set final_at = now() - interval '1 minute' where id::text = current_setting('t.pl');
set local role authenticated;
do $$ declare s record; r text; begin
  for s in select * from (values
    (14, 'رصدةٌ بعد الاعتماد', $q$select public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,5::smallint)->>'occurrence_ar'$q$),
    (15, 'القياسُ بعدها', $q$select (r->>'state')||' · '||coalesce(r->>'state_ar','∅')||' · قبل '||coalesce(r->>'pre_ar','∅')||' · بعد '||coalesce(r->>'post_ar','∅')||' · can_refer '||(r->>'can_refer') from (select public.v2_response_check(current_setting('t.r4')::uuid) r) z$q$),
    (16, 'الإحالة', $q$select (r->>'note')||' ‖ '||((r->'file') - 'response')::text from (select public.v2_refer_committee(current_setting('t.r4')::uuid,null,'لم يستجب بعد الخطّة','دراسةُ حاله') r) z$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
select n::text as "#", left(current_setting('t.s'||n),700) as النتيجة from generate_series(1,16) n;
rollback;
