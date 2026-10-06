-- فحص ٥ · اللجان: مسارُ الاجتماع من الدعوة إلى الاعتماد، وتبديلُ الصوت.
-- لجنةُ التوجيه في طُفيل: الرئيس مفرح، والمقرّر سعيد. كلُّه داخل begin … rollback.
begin;

select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.student',(select e.student_id::text from v2.enrolments e
          where e.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992' and e.status='active' order by e.student_id limit 1),true),
       set_config('t.other',(select e.student_id::text from v2.enrolments e
          where e.school_id='f789f9ea-e474-49bc-86e0-3449258815f8' and e.status='active' order by e.student_id limit 1),true),
       set_config('t.p_chair',(select person_id::text from v2.app_users where id='11be0946-ff39-4eb7-8a74-023b580479be'),true),
       set_config('t.p_rap',(select person_id::text from v2.app_users where id='52bc11f6-8e82-44cd-9f4d-e9bf43aee128'),true),
       set_config('t.members',(select count(*)::text from v2.committee_members where committee_key='guidance'
          and school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992' and ended_on is null),true),
       set_config('t.quorum',coalesce(v2.quorum_of('7a847bb1-9b14-41ad-b9ba-7c8dee61a992','guidance')::text,'غيرُ محدَّد'),true);

-- المقرّر
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'يدعو إلى اجتماع', null::text, $q$select public.v2_meeting_call('7a847bb1-9b14-41ad-b9ba-7c8dee61a992','guidance','شهري',current_date,'08:00','المكتب','جدول')::text$q$)
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
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (2, 'يدعو بتاريخٍ مضى', null::text, $q$select public.v2_meeting_call('7a847bb1-9b14-41ad-b9ba-7c8dee61a992','guidance','شهري',current_date-1,'08:00','المكتب','جدول')::text$q$),
    (3, 'يدعو اليوم', 'meet', $q$select public.v2_meeting_call('7a847bb1-9b14-41ad-b9ba-7c8dee61a992','guidance','شهري',current_date,'08:00','المكتب','جدول')->>'meeting'$q$),
    (4, 'بندٌ لطالبِ مدرسةٍ أخرى', null::text, $q$select public.v2_meeting_item(current_setting('t.meet')::uuid,'طالب','بند',current_setting('t.other')::uuid,null,null)::text$q$),
    (5, 'بندٌ لطالبٍ من المدرسة', 'item', $q$select public.v2_meeting_item(current_setting('t.meet')::uuid,'طالب','بند',current_setting('t.student')::uuid,null,null)->>'item'$q$)
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
    (6, 'يصوّت قبل تسجيل حضوره', null::text, $q$select public.v2_meeting_vote(current_setting('t.item')::uuid,'موافق',null,null)::text$q$)
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
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (7, 'يسجّل حضورَه', null::text, $q$select public.v2_meeting_attend(current_setting('t.meet')::uuid,current_setting('t.p_chair')::uuid,'حاضر',null)::text$q$),
    (8, 'يسجّل حضورَ المقرّر', null::text, $q$select public.v2_meeting_attend(current_setting('t.meet')::uuid,current_setting('t.p_rap')::uuid,'حاضر',null)::text$q$)
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
    (9, 'يخالف بلا رأيٍ مكتوب', null::text, $q$select public.v2_meeting_vote(current_setting('t.item')::uuid,'مخالف',null,null)::text$q$),
    (10, 'يوافق', null::text, $q$select public.v2_meeting_vote(current_setting('t.item')::uuid,'موافق',null,null)::text$q$),
    (11, 'يبدّل صوتَه بلا سبب', null::text, $q$select public.v2_meeting_vote(current_setting('t.item')::uuid,'مخالف','رأيي',null)::text$q$),
    (12, 'يبدّل صوتَه بسبب', null::text, $q$select public.v2_meeting_vote(current_setting('t.item')::uuid,'مخالف','رأيي','ظهر جديد')::text$q$),
    (13, 'يُقفل البندَ قبل أن يصوّت الجميع', null::text, $q$select public.v2_meeting_close_item(current_setting('t.item')::uuid,'نوقش','قرار',null,null,null)::text$q$)
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
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (14, 'يُقفل البند (وهو للمقرّر)', null::text, $q$select public.v2_meeting_close_item(current_setting('t.item')::uuid,'نوقش','قرار',null,null,null)::text$q$),
    (15, 'يوافق', null::text, $q$select public.v2_meeting_vote(current_setting('t.item')::uuid,'موافق',null,null)::text$q$),
    (16, 'يعتمد قبل التوثيق', null::text, $q$select public.v2_meeting_approve(current_setting('t.meet')::uuid)::text$q$)
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
    (17, 'يُقفل البند', null::text, $q$select public.v2_meeting_close_item(current_setting('t.item')::uuid,'نوقش','قرار',null,null,null)::text$q$),
    (18, 'يوثّق المحضر', null::text, $q$select public.v2_meeting_minute(current_setting('t.meet')::uuid,'09:00')::text$q$)
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
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (19, 'يعتمد المحضر', null::text, $q$select public.v2_meeting_approve(current_setting('t.meet')::uuid)::text$q$),
    (20, 'يصوّت بعد الاعتماد', null::text, $q$select public.v2_meeting_vote(current_setting('t.item')::uuid,'مخالف','رأي',null)::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الرئيس · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", current_setting('t.s'||n) as النتيجة from generate_series(1,20) n
union all select 'أ', 'صوتُ المقرّر في المحضر: '||coalesce(v.prev_vote,'—')||' ← '||v.vote||' · السبب: '||coalesce(v.change_note,'—')
  from v2.meeting_votes v where v.item_id=nullif(current_setting('t.item',true),'')::uuid and v.person_id=current_setting('t.p_rap')::uuid
union all select 'ب', 'الأعضاء '||current_setting('t.members')||' · الحاضرون '||
  (select count(*) from v2.meeting_attendance where meeting_id=nullif(current_setting('t.meet',true),'')::uuid and state='حاضر')||
  ' · النصاب '||current_setting('t.quorum')||' · quorum_met='||
  coalesce((select quorum_met::text from v2.committee_meetings where id=nullif(current_setting('t.meet',true),'')::uuid),'—');

rollback;
