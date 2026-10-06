-- فحص ٢٤ · الإنابة في الصفات — بالنداءات التي ترسلها inaba.js وسطرُ الرأس في common.js.
-- كلُّه داخل begin … rollback: الإنابةُ تُنشأ وتُلغى ويزول أثرُها بالتراجع. لا حسابَ يُمسّ ولا حذف.
-- مفرح (مالكٌ — يمرّ بحرّاس الصفة بقرارٍ موثّق) يُصدر؛ وسعيد (موجّهٌ في الطفيل) يُناب في «مدير المدرسة».
-- ثمّ يُرى بعين سعيد: v2_my_acting، وحارسُ الصفة يقبله بالإنابة — يُثبَت برفضٍ من حارسٍ يقع بعد حارس الصفة (لا إنابةَ بلا سبب)، فلا يُكتب شيء.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '20s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.mof',(select person_id::text from v2.app_users where id='11be0946-ff39-4eb7-8a74-023b580479be'),true),
       set_config('t.saeed',(select person_id::text from v2.app_users where id='52bc11f6-8e82-44cd-9f4d-e9bf43aee128'),true),
       set_config('t.other',(select a.person_id::text from v2.assignments a where a.school_id='f789f9ea-e474-49bc-86e0-3449258815f8'::uuid and a.ended_on is null
          and not exists (select 1 from v2.assignments b where b.person_id=a.person_id and b.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid and b.ended_on is null) limit 1),true),
       set_config('t.ends',(current_date+6)::text,true);

-- ① مفرح يُصدر
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'اللوح قبلُ', null::text, $q$select 'live '||jsonb_array_length(r->'live')||' · past '||jsonb_array_length(r->'past')||' · vacant '||jsonb_array_length(r->'vacant')||' ‖ '||coalesce((r->'vacant')::text,'—') from (select public.v2_delegations_board(current_setting('t.school')::uuid) r) z$q$),
    (2, 'إنابةٌ بلا سبب', null, $q$select public.v2_delegate_add(current_setting('t.school')::uuid,'principal',current_setting('t.saeed')::uuid,null,null,'  ',null)::text$q$),
    (3, 'يُناب صاحبُ الصفة عن نفسه (وكيل شؤون الطلاب ← مفرح)', null, $q$select public.v2_delegate_add(current_setting('t.school')::uuid,'deputy_students',current_setting('t.mof')::uuid,null,null,'فحص',null)::text$q$),
    (4, 'مُنابٌ من مدرسةٍ أخرى', null, $q$select public.v2_delegate_add(current_setting('t.school')::uuid,'principal',current_setting('t.other')::uuid,null,null,'فحص',null)::text$q$),
    (5, 'نهايةٌ قبل البداية', null, $q$select public.v2_delegate_add(current_setting('t.school')::uuid,'principal',current_setting('t.saeed')::uuid,current_date,current_date-1,'فحص',null)::text$q$),
    (6, 'وظيفةٌ غيرُ معروفة', null, $q$select public.v2_delegate_add(current_setting('t.school')::uuid,'no_such_post',current_setting('t.saeed')::uuid,null,null,'فحص',null)::text$q$),
    (7, 'إنابةُ سعيد في «مدير المدرسة» أسبوعًا', 'dlg', $q$select r->>'delegation' from (select public.v2_delegate_add(current_setting('t.school')::uuid,'principal',current_setting('t.saeed')::uuid,null,current_setting('t.ends')::date,'إجازةُ المدير — فحص','فحص-٢٤') r) z$q$),
    (8, 'تكرارُها', null, $q$select public.v2_delegate_add(current_setting('t.school')::uuid,'principal',current_setting('t.saeed')::uuid,null,null,'فحص',null)::text$q$),
    (9, 'اللوح بعدها (live[0])', null, $q$select 'live '||jsonb_array_length(r->'live')||' ‖ '||(r->'live'->0)::text from (select public.v2_delegations_board(current_setting('t.school')::uuid) r) z$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'مفرح · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- ② بعين سعيد (موجّهٌ أصالةً · مديرٌ إنابةً)
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (10, 'v2_my_acting', null::text, $q$select public.v2_my_acting(current_setting('t.school')::uuid)::text$q$),
    (11, 'حارسُ الصفة يقبله بالإنابة (v2_delegate_add بلا سبب ⇒ يُنتظر رفضُ السبب لا رفضُ الصفة)', null, $q$select public.v2_delegate_add(current_setting('t.school')::uuid,'deputy',current_setting('t.mof')::uuid,null,null,'',null)::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'سعيد · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- ③ مفرح يُلغي
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
do $$ declare s record; r text; begin
  for s in select * from (values
    (12, 'إلغاءٌ بلا سبب', null::text, $q$select public.v2_delegate_revoke(current_setting('t.dlg')::uuid,'')::text$q$),
    (13, 'إلغاءٌ بسبب', null, $q$select public.v2_delegate_revoke(current_setting('t.dlg')::uuid,'عاد المدير — فحص')::text$q$),
    (14, 'إلغاؤها ثانيةً', null, $q$select public.v2_delegate_revoke(current_setting('t.dlg')::uuid,'فحص')::text$q$),
    (15, 'اللوح بعد الإلغاء', null, $q$select 'live '||jsonb_array_length(r->'live')||' · past '||jsonb_array_length(r->'past')||' ‖ '||(r->'past'->0)::text from (select public.v2_delegations_board(current_setting('t.school')::uuid) r) z$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'مفرح · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
-- خارجَ الدور (الجدولُ محروسٌ بـ RLS): الصفُّ باقٍ لم يُحذف
select set_config('t.s16','الصفُّ باقٍ لم يُحذف ⇐ '||count(*)||' صفّ · revoked_why '||coalesce(max(revoked_why),'—')||' · from_person '||coalesce(max(from_person::text),'—'),true)
  from v2.delegations where id=nullif(current_setting('t.dlg'),'')::uuid;

-- ④ سعيد بعد الإلغاء
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
do $$ declare r text; begin
  begin r := 'نفذ: '||public.v2_my_acting(current_setting('t.school')::uuid)::text; exception when others then r := 'رُفض: '||sqlerrm; end;
  perform set_config('t.s17', 'سعيد · v2_my_acting بعد الإلغاء ⇐ '||r, true);
  begin r := 'نفذ: '||public.v2_delegate_add(current_setting('t.school')::uuid,'deputy',current_setting('t.mof')::uuid,null,null,'',null)::text; exception when others then r := 'رُفض: '||sqlerrm; end;
  perform set_config('t.s18', 'سعيد · حارسُ الصفة بعد الإلغاء ⇐ '||r, true);
end $$;
reset role;

select n::text as "#", left(current_setting('t.s'||n),1200) as النتيجة from generate_series(1,18) n;
rollback;
