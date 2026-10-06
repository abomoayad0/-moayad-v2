-- فحص ٢٦ · الوصولُ والاصطفافُ والانصراف — بالنداءات التي ترسلها wusul.js.
-- كلُّه داخل begin … rollback. الهويّة: مفرح بصفة وكيل شؤون الطلاب في الطفيل. لا حسابَ يُمسّ ولا حذف.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '20s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true), set_config('t.d',current_date::text,true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  -- طالبٌ لم يُرصد اليوم، وآخرُ غيرُه
  perform set_config('t.a',(select student_id::text from public.v2_day_list(current_setting('t.school')::uuid,current_setting('t.d')::date) where state='unrecorded' order by student_no limit 1),true);
  perform set_config('t.b',(select student_id::text from public.v2_day_list(current_setting('t.school')::uuid,current_setting('t.d')::date) where state='unrecorded' order by student_no offset 1 limit 1),true);
  for s in select * from (values
    (1, 'v2_me: مفاتيحُ الأبواب الثلاثة', $q$select 'assembly='||coalesce(r->'can'->>'record_assembly','—')||' · arrival='||coalesce(r->'can'->>'record_arrival','—')||' · dismissal='||coalesce(r->'can'->>'record_dismissal','—') from (select public.v2_me() r) z$q$),
    (2, 'ملخّصُ اليوم', $q$select row_to_json(x)::text from public.v2_day_summary(current_setting('t.school')::uuid,current_setting('t.d')::date) x$q$),
    (3, 'فصولُ اليوم', $q$select count(*)||' فصول ‖ '||string_agg(label_ar||': '||enrolled||'/'||unrecorded||' done='||is_done,' · ') from public.v2_day_classes(current_setting('t.school')::uuid,current_setting('t.d')::date)$q$),
    (4, 'اصطفاف: حالةٌ غيرُ معروفة', $q$select public.v2_record_assembly(current_setting('t.a')::uuid,current_setting('t.d')::date,'x')::text$q$),
    (5, 'اصطفاف: الطالب a حاضر', $q$select public.v2_record_assembly(current_setting('t.a')::uuid,current_setting('t.d')::date,'attended')::text$q$),
    (6, 'اصطفاف: الطالب b غائب', $q$select public.v2_record_assembly(current_setting('t.b')::uuid,current_setting('t.d')::date,'not_arrived')::text$q$),
    (7, 'الطالبان بعدُ في القائمة', $q$select string_agg(state||'/'||coalesce(assembly_state,'∅')||'/'||coalesce(assembly_ar,'∅'),' · ') from public.v2_day_list(current_setting('t.school')::uuid,current_setting('t.d')::date) where student_id in (current_setting('t.a')::uuid,current_setting('t.b')::uuid)$q$),
    (8, 'وصول: b بلا وقت', $q$select public.v2_record_arrival(current_setting('t.b')::uuid,current_setting('t.d')::date,null,'enter_class',null,null)::text$q$),
    (9, 'وصول: b ٠٧:٤٠ دخولُ الفصل', $q$select public.v2_record_arrival(current_setting('t.b')::uuid,current_setting('t.d')::date,time '07:40','enter_class',null,'فحص')::text$q$),
    (10, 'b بعد الوصول', $q$select state||' · '||coalesce(arrived_at::text,'∅')||' · late='||coalesce(minutes_late::text,'∅')||' · permit='||has_permit||'/'||coalesce(permit_decision,'∅') from public.v2_day_list(current_setting('t.school')::uuid,current_setting('t.d')::date) where student_id=current_setting('t.b')::uuid$q$),
    (11, 'انصراف: a بلا وقت', $q$select (select row_to_json(x)::text from public.v2_record_dismissal(current_setting('t.a')::uuid,current_setting('t.d')::date,null,null) x)$q$),
    (12, 'انصراف: a بعد نهاية الدوام بقليل (١٣:٤٠)', $q$select (select row_to_json(x)::text from public.v2_record_dismissal(current_setting('t.a')::uuid,current_setting('t.d')::date,time '13:40','فحص') x)$q$),
    (13, 'انصرافاتُ اليوم', $q$select count(*)||' ‖ '||coalesce(string_agg(student_name||' · '||left_at||' · '||minutes_after||' · '||threshold_ar||' · '||coalesce(action_taken,'∅')||' · '||coalesce(recorded_role,'∅'),' | '),'—') from public.v2_day_dismissals(current_setting('t.school')::uuid,current_setting('t.d')::date)$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
select n::text as "#", left(current_setting('t.s'||n),700) as النتيجة from generate_series(1,13) n
union all select 'أ', 'a '||coalesce(current_setting('t.a'),'—')||' · b '||coalesce(current_setting('t.b'),'—')||' · اليوم '||current_setting('t.d');
rollback;
