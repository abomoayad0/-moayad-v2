-- فحص ٤١ · حرّاسُ الصفة بحساباتٍ ليست مالكًا ولا مديرَ نظام — المعلّم · الموجّه · المساعدُ الإداريّ · الطالب
-- لأنّ assert_role يُجيز owner و admin قبل أيّ صفة، فلا يُقبل «مرّ» من حساب مفرح. كلُّه داخل begin…rollback
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
do $$ begin
  perform set_config('t.rec',(select br.id::text from v2.behavior_records br where br.school_id::text=current_setting('t.school') and br.status='open' order by br.created_at desc limit 1),true);
  perform set_config('t.entry',coalesce((select i.entry_id::text from v2.form_inbox i join v2.students s on s.id=i.student_id join v2.form_entries e on e.id=i.entry_id where s.user_id='ff4268af-1706-4b2f-a4bf-18042beab878' and i.to_kind='student' and e.status='final' limit 1),''),true);
  perform set_config('t.signers',coalesce((select array_to_string(f.signers,' · ') from v2.form_entries e join v2.official_forms f on f.form_no=e.form_no where e.id::text=nullif(current_setting('t.entry'),'')),'∅'),true);
end $$;
set local role authenticated;
-- ① المعلّم
set local request.jwt.claims = '{"sub":"5e17dd28-15ef-4c80-b7ba-0cb3d9e4141d","role":"authenticated"}';
select public.v2_act_as('subject_teacher', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'المعلّم · ما ينتظر الصادر', $q$select (public.v2_outgoing_pending(current_setting('t.school')::uuid))->>'summary_ar'$q$),
    (2, 'المعلّم · إنشاءُ صادر', $q$select (public.v2_outgoing_create('م','ج'))->>'state_ar'$q$),
    (3, 'المعلّم · سجلُّ الصادر', $q$select (public.v2_outgoing_register(current_setting('t.school')::uuid))->>'summary_ar'$q$),
    (4, 'المعلّم · سجلُّ الوارد', $q$select count(*)::text||' صفًّا' from public.v2_mail_inbox(current_setting('t.school')::uuid,null,365)$q$),
    (5, 'المعلّم · تسجيلُ وارد', $q$select (public.v2_mail_register('ج','م',null,null,current_date,null,'عادي',null))->>'note_ar'$q$),
    (6, 'المعلّم · قائمةُ المتبقّي', $q$select (public.v2_open_records(current_setting('t.school')::uuid))->>'summary_ar'$q$),
    (7, 'المعلّم · إلغاءُ رصدة', $q$select (public.v2_record_void(nullif(current_setting('t.rec'),'')::uuid,'س','أُلغي'))->>'note_ar'$q$),
    (8, 'المعلّم · صندوقُه', $q$select (r->>'who_ar')||' · '||(r->>'count') from (select public.v2_my_form_inbox() r) z$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—'); exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
-- ② الموجّه
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (9, 'الموجّه · ما ينتظر الصادر', $q$select (public.v2_outgoing_pending(current_setting('t.school')::uuid))->>'summary_ar'$q$),
    (10, 'الموجّه · قائمةُ المتبقّي', $q$select (public.v2_open_records(current_setting('t.school')::uuid))->>'summary_ar'$q$),
    (11, 'الموجّه · إلغاءُ رصدة', $q$select (public.v2_record_void(nullif(current_setting('t.rec'),'')::uuid,'س','أُلغي'))->>'note_ar'$q$),
    (12, 'الموجّه · توجيهُ وارد', $q$select (public.v2_mail_direct(gen_random_uuid(),'[]'::jsonb))->>'note_ar'$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—'); exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
-- ③ المساعدُ الإداريّ
set local request.jwt.claims = '{"sub":"fad7dfa7-8f6f-4c5b-9fbf-c0a2c308476a","role":"authenticated"}';
select public.v2_act_as('admin_assistant', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (13, 'المساعد · ما ينتظر الصادر', $q$select (public.v2_outgoing_pending(current_setting('t.school')::uuid))->>'summary_ar'$q$),
    (14, 'المساعد · إنشاءُ صادر', $q$select (set_config('t.m1', r->>'mail', true) is not null)::text||' '||(r->>'state_ar') from (select public.v2_outgoing_create('موضوع','جهة') r) z$q$),
    (15, 'المساعد · توقيعُه', $q$select (public.v2_outgoing_sign(nullif(current_setting('t.m1'),'')::uuid))->>'serial_ar'$q$),
    (16, 'المساعد · إلغاؤه', $q$select (public.v2_outgoing_cancel(nullif(current_setting('t.m1'),'')::uuid,'سبب'))->>'state_ar'$q$),
    (17, 'المساعد · إنشاءُ صادرٍ سرّيّ', $q$select (set_config('t.m2', r->>'mail', true) is not null)::text||' '||(r->>'state_ar') from (select public.v2_outgoing_create('سرّ','جهة',null,'letter','سري') r) z$q$),
    (18, 'المساعد · فتحُ السرّيّ', $q$select (public.v2_outgoing_one(nullif(current_setting('t.m2'),'')::uuid))->>'subject'$q$),
    (19, 'المساعد · تسجيلُ وارد', $q$select (public.v2_mail_register('جهة','موضوع',null,null,current_date,null,'عادي',null))->>'note_ar'$q$),
    (20, 'المساعد · تسجيلُ واردٍ سرّيّ', $q$select (public.v2_mail_register('جهة','سرّ',null,null,current_date,null,'سري',null))->>'note_ar'$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—'); exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
-- ④ الطالبُ بحسابه
set local request.jwt.claims = '{"sub":"ff4268af-1706-4b2f-a4bf-18042beab878","role":"authenticated"}';
do $$ declare s record; r text; begin
  for s in select * from (values
    (21, 'الطالب · ما ينتظر الصادر', $q$select (public.v2_outgoing_pending(current_setting('t.school')::uuid))->>'summary_ar'$q$),
    (22, 'الطالب · امتناعٌ بلا سبب (موقّعو النموذج: '||current_setting('t.signers')||')', $q$select (public.v2_form_sign(nullif(current_setting('t.entry'),'')::uuid,'الطالب',false,null))->>'note_ar'$q$),
    (23, 'الطالب · توقيعٌ بصفة وليّ الأمر', $q$select (public.v2_form_sign(nullif(current_setting('t.entry'),'')::uuid,'ولي الأمر',true,null))->>'note_ar'$q$),
    (24, 'الطالب · توقيعُه', $q$select (public.v2_form_sign(nullif(current_setting('t.entry'),'')::uuid,'الطالب',true,null))->>'note_ar'$q$),
    (25, 'الطالب · توقيعُه ثانيةً', $q$select (public.v2_form_sign(nullif(current_setting('t.entry'),'')::uuid,'الطالب',true,null))->>'note_ar'$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—'); exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
select n, current_setting('t.s'||n, true) as result from generate_series(1,25) n;
rollback;
