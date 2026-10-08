-- فحص ٣٥ · مسارُ الخطّة كاملًا بعد إصلاح steps · v2_problems · وليُّ الأمر: الخطّة والنصيحةُ والردُّ بالحدث
-- داخل begin … rollback. التهيئةُ الوحيدة: تقديمُ final_at دقيقةً ليقع الرصدُ بعد الاعتماد في معاملةٍ واحدة
begin;
set local lock_timeout = '5s';
set local statement_timeout = '40s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
select set_config('t.stu','d4c11fbb-c7d1-4242-954b-519d96aaa9b3',true);
select set_config('t.pl','',true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'الرصدات ١–٤ على ابن بندر (٤٣)', $q$select string_agg(z, ' · ') from (select set_config('t.r'||k, public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,k::smallint)->>'record', true) is not null and true as ok, k::text z from generate_series(1,4) k) q$q$),
    (2, 'كتابةُ الخطّة (خطوتان بسطرين)', $q$select (set_config('t.pl', r->>'plan', true) is not null)::text||' · '||(r->>'note') from (select public.v2_plan_write(current_setting('t.stu')::uuid,current_setting('t.r4')::uuid,null,null,'ينام في الحصّة','يضع رأسه','السهر','يفوته الشرح','الراحة','تنبيهان','يبقى منتبهًا',E'يُجلس في الأمام\nيُكلَّف بمهمّة',current_date,current_date+14) r) z$q$),
    (3, 'v2_plan_of', $q$select (r->0->>'state_ar')||' · steps «'||replace(r->0->>'steps',E'\n',' ⏎ ')||'» · steps_list '||(r->0->'steps_list')::text||' · can_final '||(r->0->>'can_final') from (select public.v2_plan_of(current_setting('t.stu')::uuid) r) z$q$),
    (4, 'تعديلُ المسودّة (ثلاثُ خطوات)', $q$select (public.v2_plan_write(current_setting('t.stu')::uuid,null,null,current_setting('t.pl')::uuid,'ينام في الحصّة',null,null,null,null,null,'يبقى منتبهًا',E'يُجلس في الأمام\nيُكلَّف بمهمّة\nيُتابَع مع وليّه',null,null)->>'note')||' · '||jsonb_array_length(public.v2_plan_of(current_setting('t.stu')::uuid)->0->'steps_list')$q$),
    (5, 'اعتمادٌ بلا رأي المعلّم', $q$select public.v2_plan_final(current_setting('t.pl')::uuid,'أعتمد')::text$q$),
    (6, 'رأيُ معلّم الفصل', $q$select public.v2_plan_opinion(current_setting('t.pl')::uuid,'teacher','ينعس في الأولى')::text$q$),
    (7, 'اعتمادٌ بغير «أعتمد»', $q$select public.v2_plan_final(current_setting('t.pl')::uuid,'نعم')::text$q$),
    (8, 'اعتمادٌ بـ«أعتمد»', $q$select public.v2_plan_final(current_setting('t.pl')::uuid,'أعتمد')->>'note'$q$),
    (9, 'تعديلُ المعتمدة', $q$select public.v2_plan_write(current_setting('t.stu')::uuid,null,null,current_setting('t.pl')::uuid,'x',null,null,null,null,null,'y','z',null,null)::text$q$),
    (10, 'القياسُ بلا رصدٍ بعدها', $q$select (r->>'state')||' · '||coalesce(r->>'state_ar','∅')||' · can_refer '||(r->>'can_refer')||' · '||coalesce(r->>'by','∅') from (select public.v2_response_check(current_setting('t.r4')::uuid) r) z$q$),
    (11, 'الإحالةُ و«تعدّل»', $q$select public.v2_refer_committee(current_setting('t.r4')::uuid,null,'لم يستجب','دراسةُ حاله')::text$q$),
    (12, 'v2_problems(الدرجة ١)', $q$select jsonb_array_length(r)||' · '||(r->0->>'text')||' · '||(r->0->>'page_ar')||' · advice_n '||(r->0->>'advice_n') from (select public.v2_problems(current_setting('t.school')::uuid,1::smallint) r) z$q$)
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
    (13, 'رصدةٌ بعد الاعتماد', $q$select public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,5::smallint)->>'occurrence_ar'$q$),
    (14, 'القياسُ بعدها', $q$select (r->>'state')||' · '||coalesce(r->>'state_ar','∅')||' · قبل '||coalesce(r->>'pre_ar','∅')||' · بعد '||coalesce(r->>'post_ar','∅')||' · can_refer '||(r->>'can_refer') from (select public.v2_response_check(current_setting('t.r4')::uuid) r) z$q$),
    (15, 'الإحالة', $q$select (r->>'note')||' ‖ '||((r->'file') - 'response')::text from (select public.v2_refer_committee(current_setting('t.r4')::uuid,null,'لم يستجب بعد الخطّة','دراسةُ حاله') r) z$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
set local request.jwt.claims = '{"sub":"c62d924e-b3a5-4142-b06b-88836829addb","role":"authenticated"}';
do $$ declare s record; r text; begin
  perform set_config('t.ev', coalesce((select x->>'event' from jsonb_array_elements(public.v2_guardian_pending(current_setting('t.stu')::uuid)) x where not (x->>'replied')::boolean order by x->>'on_date' desc limit 1),''), true);
  for s in select * from (values
    (16, 'وليُّ الأمر يقرأ الخطّة', $q$select (r->0->>'state_ar')||' · '||(r->0->>'target')||' · steps_list '||(r->0->'steps_list')::text from (select public.v2_plan_of(current_setting('t.stu')::uuid) r) z$q$),
    (17, 'وليُّ الأمر يكتب رأيَه في المعتمدة', $q$select public.v2_plan_opinion(current_setting('t.pl')::uuid,'guardian','موافق')::text$q$),
    (18, 'السجلُّ بصفة وليّ الأمر: رصدةٌ بـ record_id و advice و event', $q$select string_agg(left(x->>'event',8)||' · rec '||left(coalesce(x->>'record_id','∅'),8)||' · '||coalesce(x->>'advice','∅'),' ‖ ') from (select x from jsonb_array_elements(public.v2_student_timeline(current_setting('t.stu')::uuid,'guardian')->'events') x where x->>'kind'='behavior_record' limit 2) z$q$),
    (19, 'v2_record_advice من record_id السجلّ', $q$select public.v2_record_advice((select (x->>'record_id')::uuid from jsonb_array_elements(public.v2_student_timeline(current_setting('t.stu')::uuid,'guardian')->'events') x where x->>'record_id' is not null limit 1))->>'text'$q$),
    (20, 'دعوةُ الإجراء الرابع في v2_guardian_pending', $q$select nullif(current_setting('t.ev'),'') is not null and true$q$),
    (21, 'ردُّه بالحدث', $q$select public.v2_guardian_reply(current_setting('t.stu')::uuid,nullif(current_setting('t.ev'),'')::uuid,'دعوة','أحضر',null,null)->>'note'$q$),
    (22, 'الدعوةُ بعد ردّه', $q$select (x->>'replied')||' · '||coalesce(x->>'reply','∅') from jsonb_array_elements(public.v2_guardian_pending(current_setting('t.stu')::uuid)) x where x->>'event'=current_setting('t.ev')$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
select n::text as "#", left(current_setting('t.s'||n),700) as النتيجة from generate_series(1,22) n;
rollback;
