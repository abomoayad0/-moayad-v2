-- فحص ١٥ · شاشةُ الوكيل (viewW) على القاعدة: الحصص · السند · الرصدُ وإيقافُه بلا فصول · التعديلُ بعد الرصد · السجلُّ الزمنيّ · الشواهد · النموذج ٥.
-- كلُّه داخل begin … rollback. والفصلُ الدراسيُّ يُؤسَّس داخل التراجع بـ v2_term_save (جسرٌ للوكيل)، فلا يبقى في التقويم شيء.
-- الهويّات: مفرح بصفة وكيل شؤون الطلاب · سعيد بصفة الموجّه. لا حساب ولا كلمةَ مرور، ولا حذف.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '20s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.year',(select id::text from v2.academic_years where school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid and is_current),true),
       set_config('t.terms_before',(select count(*)::text from v2.terms t join v2.academic_years y on y.id=t.year_id where y.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid),true);
select set_config('t.a',(select e.student_id::text from v2.enrolments e where e.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid and e.status='active'
          and not exists (select 1 from v2.behavior_records b where b.student_id=e.student_id and b.problem_id in (38,41))
          and not exists (select 1 from v2.attendance a where a.student_id=e.student_id and a.on_date=current_date and a.state='absent')
          order by e.student_id limit 1),true);

-- الوكيل
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'حصصُ المدرسة', null::text, $q$select jsonb_array_length(r)||' · '||coalesce((select string_agg((x->>'no_ar')||'='||(x->>'label'),' · ') from jsonb_array_elements(r) x),'—') from (select public.v2_periods('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid) r) z$q$),
    (2, 'السلوك 41: page_ar والنصّ', null::text, $q$select (x->>'text')||' · '||coalesce(x->>'page_ar','—')||' · '||coalesce(x->>'source','—') from jsonb_array_elements(public.v2_conduct_list(current_setting('t.a')::uuid)) x where (x->>'id')::int=41$q$),
    (3, 'يرصد ولا فصولَ في التقويم', null::text, $q$select (r->>'headline')||' ‖ page_ar='||coalesce(r->>'page_ar','—')||' · record='||(r->>'record') from (select public.v2_record_behavior(current_setting('t.a')::uuid,41,null,null,1::smallint) r) z$q$),
    (4, 'يؤسّس الفصلَ الأوّل (داخل التراجع)', null::text, $q$select public.v2_term_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.year')::uuid,null,1::smallint,'2026-08-23','2027-01-15',true)->>'ok'$q$),
    (5, 'يرصد 38', 'r1', $q$select r->>'record' from (select public.v2_record_behavior(current_setting('t.a')::uuid,38,null,null,null) r) z$q$),
    (6, 'يرصد 41 · الحصّة ٢', 'r2', $q$select r->>'record' from (select public.v2_record_behavior(current_setting('t.a')::uuid,41,null,null,2::smallint) r) z$q$),
    (7, 'يعدّل رصدتَه: المكان والملاحظة', null::text, $q$select public.v2_record_amend(current_setting('t.r1')::uuid,'الساحة','وصل بعد الطابور',null,null,null,null)::text$q$),
    (8, 'يعدّل رصدتَه: مضبوطات', null::text, $q$select public.v2_record_amend(current_setting('t.r2')::uuid,null,null,false,false,true,false)::text$q$),
    (9, 'البطاقةُ: المكانُ بعد التعديل', null::text, $q$select (select string_agg(coalesce(x->>'problem','')||' @ '||coalesce(x->>'place','—')||' · '||coalesce(x->>'note','—'),' ‖ ') from jsonb_array_elements(public.v2_student_card(current_setting('t.a')::uuid)->'behavior') x)$q$),
    (10, 'السجلُّ الزمنيّ (null)', null::text, $q$select jsonb_array_length(r->'events')||' · '||coalesce((select string_agg((e->>'kind')||': '||(e->>'title')||' — '||coalesce(e->>'body',''),' ‖ ') from jsonb_array_elements(r->'events') e),'') from (select public.v2_student_timeline(current_setting('t.a')::uuid,null) r) z$q$),
    (11, 'الشواهدُ بانتظاره', null::text, $q$select jsonb_array_length(public.v2_entries_pending('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid))::text$q$),
    (12, 'النموذج ٥ للطالب', null::text, $q$select left((select string_agg(k,',' order by k) from jsonb_object_keys(d) k),300)||' ‖ '||left(d::text,900) from (select public.v2_form_open(5::smallint,current_setting('t.a')::uuid,null,null) d) z$q$),
    (13, 'v2_me للرأس: role_ar · acting_school · can', null::text, $q$select coalesce(r->>'role_ar','—')||' · '||coalesce(r->>'acting_school','—')||' · can.record_behavior='||coalesce(r->'can'->>'record_behavior','—')||' · roles '||coalesce(jsonb_array_length(r->'roles')::text,'—') from (select public.v2_me() r) z$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الوكيل · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- الموجّه
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (14, 'الموجّه يعدّل رصدةَ الوكيل', null::text, $q$select public.v2_record_amend(current_setting('t.r1')::uuid,'الفصل',null,null,null,null,null)::text$q$),
    (15, 'الموجّه يرى الشواهد', null::text, $q$select jsonb_array_length(public.v2_entries_pending('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid))::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الموجّه · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- تجهيز: رصدةُ الأمس (يُرجَع تاريخُها داخل التراجع) لتجربة «لا تُعدَّل بعد يومها»
update v2.behavior_records set created_at = created_at - interval '1 day' where id = nullif(current_setting('t.r2',true),'')::uuid;

-- الوكيل
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
do $$ declare s record; r text; begin
  for s in select * from (values
    (16, 'يعدّل رصدةَ الأمس', null::text, $q$select public.v2_record_amend(current_setting('t.r2')::uuid,'المقصف',null,null,null,null,null)::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الوكيل · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", left(current_setting('t.s'||n),1200) as النتيجة from generate_series(1,16) n
union all select 'أ', 'فصولُ طُفيل قبل الفحص: '||current_setting('t.terms_before');
rollback;
