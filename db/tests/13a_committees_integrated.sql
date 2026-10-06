-- فحص ١٣أ (الإصدار ٢، بعد حرّاس المحضر والترحيل و duty_id) · اللجنةُ المتكاملة: المهامّ · الاجتماعُ إلى الاعتماد · «ما عليّ» · إقرارُ التنفيذ · الترحيل.
-- كلُّه داخل begin … rollback. والهويّات: مفرح (وكيل شؤون الطلاب، رئيسُ لجنة التوجيه في طُفيل) · سعيد (الموجّه، مقرّرُها).
-- لا يُنشئ حسابًا ولا يمسّ كلمةَ مرور، ولا يحذف صفَّ الصفة. وما هو للمدير وحدَه (إنشاءُ اللجنة وإيقافُها) في 13b.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '20s';

select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.student',(select e.student_id::text from v2.enrolments e where e.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid and e.status='active' order by e.student_id limit 1),true),
       set_config('t.p_chair',(select person_id::text from v2.app_users where id='11be0946-ff39-4eb7-8a74-023b580479be'),true),
       set_config('t.p_rap',(select person_id::text from v2.app_users where id='52bc11f6-8e82-44cd-9f4d-e9bf43aee128'),true),
       set_config('t.duty_guide',(select id::text from v2.committee_duties where committee_key='guidance' and school_id is null order by ord limit 1),true),
       set_config('t.duty_other',(select id::text from v2.committee_duties where committee_key<>'guidance' order by ord limit 1),true),
       set_config('t.seats_before',(select string_agg(seat_role||'='||person_id,',' order by seat_role) from v2.committee_members where committee_key='guidance' and school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid and ended_on is null and seat_role in ('chair','rapporteur')),true);

-- الرئيس
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'يُنشئ لجنةً مدرسيّة', null::text, $q$select public.v2_committee_create('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,null,'لجنة فحص','غرض','[{"seat_role":"chair","post_key":"principal"},{"seat_role":"rapporteur","post_key":"counselor"},{"seat_role":"member","seat_count":3}]'::jsonb)::text$q$),
    (2, 'يُنشئ لجنةً بلا مقرّر', null::text, $q$select public.v2_committee_create('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,null,'لجنة فحص','غرض','[{"seat_role":"chair","post_key":"principal"},{"seat_role":"member","seat_count":3}]'::jsonb)::text$q$),
    (3, 'يوقف لجنةَ التوجيه (وزاريّة)', null::text, $q$select public.v2_committee_close('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance','سبب')::text$q$),
    (4, 'قائمةُ اللجان', null::text, $q$select jsonb_array_length(r)||' · وزاريّة '||(select count(*) from jsonb_array_elements(r) x where not (x->>'mine')::boolean)||' · للمدرسة '||(select count(*) from jsonb_array_elements(r) x where (x->>'mine')::boolean)||' · التوجيه: مهامّ '||(select x->>'duties' from jsonb_array_elements(r) x where x->>'key'='guidance')||' · قراراتٌ معلّقة '||(select x->>'open_tasks' from jsonb_array_elements(r) x where x->>'key'='guidance') from (select public.v2_committees_list('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid) r) z$q$),
    (5, 'مهامُّ التوجيه', null::text, $q$select jsonb_array_length(r)||' · من الدليل '||(select count(*) from jsonb_array_elements(r) x where not (x->>'mine')::boolean) from (select public.v2_committee_duties('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance') r) z$q$),
    (6, 'يعدّل مهمّةً من الدليل', null::text, $q$select public.v2_committee_duty_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance',current_setting('t.duty_guide')::uuid,'نصٌّ آخر','شهريّة',null)::text$q$),
    (7, 'يضيف مهمّةً لمدرسته', 'duty1', $q$select public.v2_committee_duty_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance',null,'متابعةُ خطط الطلاب المتعثّرين','شهريّة',null)->>'duty'$q$),
    (8, 'يعدّل مهمّتَه', null::text, $q$select public.v2_committee_duty_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance',current_setting('t.duty1')::uuid,'متابعةُ خطط المتعثّرين','فصليّة',2::smallint)->>'mode'$q$),
    (9, 'دوريّةٌ مجهولة', null::text, $q$select public.v2_committee_duty_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance',null,'مهمّة','أسبوعيّة',null)::text$q$),
    (10, 'المهامُّ بعدها', null::text, $q$select jsonb_array_length(r)||' · للمدرسة '||(select count(*) from jsonb_array_elements(r) x where (x->>'mine')::boolean) from (select public.v2_committee_duties('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance') r) z$q$),
    (11, 'النصابُ ثابتٌ 2 (ليصحّ الاعتماد)', null::text, $q$select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance',2::smallint,null,null,'فحص','fixed')->>'quorum_min'$q$),
    (12, 'يدعو إلى اجتماع', 'meet1', $q$select public.v2_meeting_call('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance','شهري',current_date,'08:00','المكتب','جدول')->>'meeting'$q$),
    (13, 'بندٌ لطالب', 'item1', $q$select public.v2_meeting_item(current_setting('t.meet1')::uuid,'طالب','خطةٌ علاجيّة',current_setting('t.student')::uuid,null,null)->>'item'$q$),
    (14, 'بندٌ عامّ', 'item2', $q$select public.v2_meeting_item(current_setting('t.meet1')::uuid,'عام','حملةُ الانضباط',null,null,null)->>'item'$q$),
    (15, 'حضورُه', null::text, $q$select public.v2_meeting_attend(current_setting('t.meet1')::uuid,current_setting('t.p_chair')::uuid,'حاضر',null)->>'ok'$q$),
    (16, 'ردُّ المقرّر عن بُعد', null::text, $q$select public.v2_meeting_attend(current_setting('t.meet1')::uuid,current_setting('t.p_rap')::uuid,'عن بُعد',null)->>'ok'$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الرئيس · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- المقرّر
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (17, 'يوافق على item1', null::text, $q$select public.v2_meeting_vote(current_setting('t.item1')::uuid,'موافق',null,null)->>'ok'$q$),
    (18, 'يوافق على item2', null::text, $q$select public.v2_meeting_vote(current_setting('t.item2')::uuid,'موافق',null,null)->>'ok'$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'المقرّر · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- الرئيس
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
do $$ declare s record; r text; begin
  for s in select * from (values
    (19, 'يوافق على item1', null::text, $q$select public.v2_meeting_vote(current_setting('t.item1')::uuid,'موافق',null,null)->>'ok'$q$),
    (20, 'يوافق على item2', null::text, $q$select public.v2_meeting_vote(current_setting('t.item2')::uuid,'موافق',null,null)->>'ok'$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الرئيس · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- المقرّر
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
do $$ declare s record; r text; begin
  for s in select * from (values
    (21, 'يُقفل البندَ الأوّل بلا منفِّذٍ ولا موعد', null::text, $q$select public.v2_meeting_close_item(current_setting('t.item1')::uuid,'نوقش','خطةٌ علاجيّة',null,null,null)->>'outcome'$q$),
    (22, 'يُقفله بموعدٍ مضى', null::text, $q$select public.v2_meeting_close_item(current_setting('t.item1')::uuid,'نوقش','خطةٌ علاجيّة',null,current_setting('t.p_chair')::uuid,current_date-1)->>'outcome'$q$),
    (23, 'يُقفله: المنفِّذ الرئيس · موعدُه اليوم', null::text, $q$select public.v2_meeting_close_item(current_setting('t.item1')::uuid,'نوقش','خطةٌ علاجيّة',null,current_setting('t.p_chair')::uuid,current_date)->>'outcome'$q$),
    (24, 'يُقفله ثانيةً قبل التوثيق', null::text, $q$select public.v2_meeting_close_item(current_setting('t.item1')::uuid,'نوقش','قرارٌ آخر',null,current_setting('t.p_chair')::uuid,current_date+3)->>'outcome'$q$),
    (25, 'يُقفل الثاني: المنفِّذُ هو · بعد أسبوع', null::text, $q$select public.v2_meeting_close_item(current_setting('t.item2')::uuid,'نوقش','حملةٌ في الطابور',null,current_setting('t.p_rap')::uuid,current_date+7)->>'outcome'$q$),
    (26, 'يوثّق المحضر', null::text, $q$select public.v2_meeting_minute(current_setting('t.meet1')::uuid,'09:00')::text$q$),
    (27, '«ما عليّ» قبل الاعتماد', null::text, $q$select jsonb_array_length(r)||coalesce(' · '||(select string_agg(coalesce(x->>'title','')||' · due '||coalesce(x->>'due','—')||' · late='||(x->>'late')||' · days_left='||coalesce(x->>'days_left','—')||' · carried='||(x->>'carried'),' ‖ ') from jsonb_array_elements(r) x),'') from (select public.v2_my_committee_tasks('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid) r) z$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'المقرّر · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- الرئيس
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
do $$ declare s record; r text; begin
  for s in select * from (values
    (28, 'يعتمد (كلُّ قرارٍ له منفِّذٌ وموعد)', null::text, $q$select public.v2_meeting_approve(current_setting('t.meet1')::uuid)::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الرئيس · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- المقرّر
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
do $$ declare s record; r text; begin
  for s in select * from (values
    (29, 'يُقفل البندَ الأوّل ثانيةً بعد الاعتماد', null::text, $q$select public.v2_meeting_close_item(current_setting('t.item1')::uuid,'نوقش','خطةٌ علاجيّة',null,current_setting('t.p_chair')::uuid,current_date-1)->>'outcome'$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'المقرّر · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- الرئيس
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
do $$ declare s record; r text; begin
  for s in select * from (values
    (30, 'يعتمد ثانيةً', null::text, $q$select public.v2_meeting_approve(current_setting('t.meet1')::uuid)::text$q$),
    (31, '«ما عليّ» (الرئيس)', null::text, $q$select jsonb_array_length(r)||coalesce(' · '||(select string_agg(coalesce(x->>'title','')||' · due '||coalesce(x->>'due','—')||' · late='||(x->>'late')||' · days_left='||coalesce(x->>'days_left','—')||' · carried='||(x->>'carried'),' ‖ ') from jsonb_array_elements(r) x),'') from (select public.v2_my_committee_tasks('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid) r) z$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الرئيس · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- المقرّر
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
do $$ declare s record; r text; begin
  for s in select * from (values
    (32, '«ما عليّ» (المقرّر)', null::text, $q$select jsonb_array_length(r)||coalesce(' · '||(select string_agg(coalesce(x->>'title','')||' · due '||coalesce(x->>'due','—')||' · late='||(x->>'late')||' · days_left='||coalesce(x->>'days_left','—')||' · carried='||(x->>'carried'),' ‖ ') from jsonb_array_elements(r) x),'') from (select public.v2_my_committee_tasks('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid) r) z$q$),
    (33, 'يُقرّ تنفيذَ قراره بلا بيان', null::text, $q$select public.v2_committee_task_done(current_setting('t.item2')::uuid,'  ',null)::text$q$),
    (34, 'يُقرّ تنفيذَه ببيان', null::text, $q$select public.v2_committee_task_done(current_setting('t.item2')::uuid,'نُفّذت الحملةُ يومَ الأحد','صورٌ في الملفّ')::text$q$),
    (35, '«ما عليّ» بعده', null::text, $q$select jsonb_array_length(r)||coalesce(' · '||(select string_agg(coalesce(x->>'title','')||' · due '||coalesce(x->>'due','—')||' · late='||(x->>'late')||' · days_left='||coalesce(x->>'days_left','—')||' · carried='||(x->>'carried'),' ‖ ') from jsonb_array_elements(r) x),'') from (select public.v2_my_committee_tasks('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid) r) z$q$),
    (36, 'يُقرّ تنفيذَه ثانيةً', null::text, $q$select public.v2_committee_task_done(current_setting('t.item2')::uuid,'مرّة أخرى',null)::text$q$),
    (37, 'يُقرّ تنفيذَ قرار غيره (وليس رئيسًا)', null::text, $q$select public.v2_committee_task_done(current_setting('t.item1')::uuid,'فعلتُه',null)::text$q$),
    (38, 'يُقفل البندَ الأوّل بعد الاعتماد بقرارٍ آخر', null::text, $q$select public.v2_meeting_close_item(current_setting('t.item1')::uuid,'نوقش','قرارٌ بُدّل بعد الاعتماد',null,current_setting('t.p_chair')::uuid,current_date+30)->>'outcome'$q$),
    (39, 'يرحّل إلى اجتماعٍ معتمد', null::text, $q$select public.v2_meeting_carry_over(current_setting('t.meet1')::uuid)::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'المقرّر · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- الرئيس
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
do $$ declare s record; r text; begin
  for s in select * from (values
    (40, 'يدعو إلى اجتماعٍ ثانٍ', 'meet2', $q$select public.v2_meeting_call('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance','شهري',current_date+1,'08:00','المكتب','جدول')->>'meeting'$q$),
    (41, 'بندٌ مربوطٌ بمهمّةٍ من الدليل', null::text, $q$select public.v2_meeting_item(current_setting('t.meet2')::uuid,'عام','مراجعةُ المهمّة',null,null,null,current_setting('t.duty_guide')::uuid)->>'ok'$q$),
    (42, 'بندٌ بمهمّةِ لجنةٍ أخرى', null::text, $q$select public.v2_meeting_item(current_setting('t.meet2')::uuid,'عام','مهمّةٌ غريبة',null,null,null,current_setting('t.duty_other')::uuid)::text$q$),
    (43, '«رحّل ما لم يُنفَّذ»', null::text, $q$select public.v2_meeting_carry_over(current_setting('t.meet2')::uuid)::text$q$),
    (44, 'يرحّل ثانيةً إلى الاجتماع نفسه', null::text, $q$select public.v2_meeting_carry_over(current_setting('t.meet2')::uuid)->>'carried'$q$),
    (45, 'يدعو إلى اجتماعٍ ثالث (والثاني مفتوح)', 'meet3', $q$select public.v2_meeting_call('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance','طارئ',current_date+2,'08:00','المكتب','جدول')->>'meeting'$q$),
    (46, 'يرحّل إلى الثالث (وقد رُحّل إلى الثاني)', null::text, $q$select public.v2_meeting_carry_over(current_setting('t.meet3')::uuid)->>'carried'$q$),
    (47, '«ما عليّ» (الرئيس) بعد الترحيل', null::text, $q$select jsonb_array_length(r)||coalesce(' · '||(select string_agg(coalesce(x->>'title','')||' · due '||coalesce(x->>'due','—')||' · late='||(x->>'late')||' · days_left='||coalesce(x->>'days_left','—')||' · carried='||(x->>'carried'),' ‖ ') from jsonb_array_elements(r) x),'') from (select public.v2_my_committee_tasks('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid) r) z$q$),
    (48, 'قائمةُ اللجان بعدها', null::text, $q$select 'التوجيه: قراراتٌ معلّقة '||(select x->>'open_tasks' from jsonb_array_elements(r) x where x->>'key'='guidance')||' · اجتماعات '||(select x->>'meetings' from jsonb_array_elements(r) x where x->>'key'='guidance') from (select public.v2_committees_list('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid) r) z$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الرئيس · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", left(current_setting('t.s'||n),500) as النتيجة from generate_series(1,48) n
union all select 'أ', 'البندُ الأوّل الآن: '||(select coalesce(decision_ar,'—')||' · منفِّذ='||coalesce((owner_person=current_setting('t.p_chair')::uuid)::text,'لا')||' · موعد='||coalesce(due_on::text,'—')||' · مرحَّلٌ إلى '||(select count(*) from v2.meeting_items x where x.carried_from=i.id)||' بند' from v2.meeting_items i where id=current_setting('t.item1')::uuid)
union all select 'ب', 'البندُ الثاني: '||(select 'نُفّذ='||(done_at is not null)::text||' · '||coalesce(done_note,'—')||' · شاهد='||coalesce(done_evidence,'—') from v2.meeting_items where id=current_setting('t.item2')::uuid)
union all select 'ج', 'مقعدا الرئيس والمقرّر: '||coalesce(current_setting('t.seats_before'),'—');

rollback;
