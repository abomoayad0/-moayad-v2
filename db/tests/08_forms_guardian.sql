-- فحص ٨ · النماذج ووليّ الأمر: نموذج (17) «تعهّد الالتزام بالحضور» من الاعتماد إلى الإلغاء،
-- وبوّابةُ وليّ الأمر: ابنُه دون غيره، وتوقيعُه منه وحده. كلُّه داخل begin … rollback.
-- p_rows يُمرَّر '[]' لأنّ rows_data NOT NULL ولا يحوّل الجسرُ null إليه (انظر المخرَج المتوقَّع).
-- الموظّف: مفرح بصفة وكيل شؤون الطلاب في طُفيل. وليّ الأمر: حسابُ الفحص c62d924e (بلا حسابٍ في app_users).
begin;

select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.child',(select student_id::text from v2.guardians where user_id='c62d924e-b3a5-4142-b06b-88836829addb' limit 1),true);
select set_config('t.other',(select e.student_id::text from v2.enrolments e where e.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992' and e.status='active'
          and e.student_id<>current_setting('t.child')::uuid order by e.student_id limit 1),true);

-- الوكيل
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'يعتمد النموذجَ بلا نصّ التعهّد', null::text, $q$select public.v2_form_save(17::smallint,'{}'::jsonb,'[]'::jsonb,current_setting('t.child')::uuid,null,null,null,true)::text$q$),
    (2, 'يعتمد النموذجَ كاملًا', 'entry', $q$select public.v2_form_save(17::smallint,'{"pledge_text":"أتعهّد"}'::jsonb,'[]'::jsonb,current_setting('t.child')::uuid,null,null,null,true)->>'entry_id'$q$),
    (3, 'يعدّل نموذجًا معتمدًا', null::text, $q$select public.v2_form_save(17::smallint,'{"pledge_text":"تعديل"}'::jsonb,'[]'::jsonb,current_setting('t.child')::uuid,null,null,current_setting('t.entry')::uuid,true)::text$q$),
    (4, 'يوقّع عن وليّ الأمر', null::text, $q$select public.v2_form_sign(current_setting('t.entry')::uuid,'ولي الأمر',true,null)::text$q$),
    (5, 'يوثّق امتناعَ وليّ الأمر بلا سبب', null::text, $q$select public.v2_form_sign(current_setting('t.entry')::uuid,'ولي الأمر',false,null)::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الوكيل · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- وليّ الأمر
set local role authenticated;
set local request.jwt.claims = '{"sub":"c62d924e-b3a5-4142-b06b-88836829addb","role":"authenticated"}';
do $$ declare s record; r text; begin
  for s in select * from (values
    (6, 'بوّابتُه', null::text, $q$select (public.v2_guardian_me() is not null)::text$q$),
    (7, 'سجلُّ ابنه', null::text, $q$select (public.v2_guardian_child(current_setting('t.child')::uuid) is not null)::text$q$),
    (8, 'سجلُّ طالبٍ ليس ابنَه', null::text, $q$select (public.v2_guardian_child(current_setting('t.other')::uuid) is not null)::text$q$),
    (9, 'صندوقُ نماذجه', null::text, $q$select count(*)||' نموذجًا · منها هذا: '||count(*) filter (where entry_id=current_setting('t.entry')::uuid)||' · ينتظر توقيعَه: '||coalesce(bool_or(needs_sign) filter (where entry_id=current_setting('t.entry')::uuid)::text,'—') from public.v2_guardian_forms()$q$),
    (10, 'يوقّع', null::text, $q$select public.v2_form_sign(current_setting('t.entry')::uuid,'ولي الأمر',true,null)::text$q$),
    (11, 'يوقّع ثانيةً', null::text, $q$select public.v2_form_sign(current_setting('t.entry')::uuid,'ولي الأمر',true,null)::text$q$),
    (12, 'يوقّع بصفة المدير', null::text, $q$select public.v2_form_sign(current_setting('t.entry')::uuid,'مدير/مديرة المدرسة',true,null)::text$q$),
    (13, 'يدوّن مخالفةً على ابنه', null::text, $q$select public.v2_record_behavior(current_setting('t.child')::uuid,1,'الفصل','x')::text$q$),
    (14, 'يقرأ الإعدادات', null::text, $q$select public.v2_setting_rows('class_sections','7a847bb1-9b14-41ad-b9ba-7c8dee61a992')::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'وليّ الأمر · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- الوكيل
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (15, 'يُلغي بلا سبب', null::text, $q$select public.v2_form_void(current_setting('t.entry')::uuid,'')::text$q$),
    (16, 'يُلغي بسبب', null::text, $q$select public.v2_form_void(current_setting('t.entry')::uuid,'فحص')::text$q$),
    (17, 'يوقّع على مُلغًى', null::text, $q$select public.v2_form_sign(current_setting('t.entry')::uuid,'مدير/مديرة المدرسة',true,null)::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الوكيل · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", left(current_setting('t.s'||n),400) as النتيجة from generate_series(1,17) n;

rollback;
