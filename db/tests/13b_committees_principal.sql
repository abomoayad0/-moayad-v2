-- فحص ١٣ب · إنشاءُ لجنةٍ مدرسيّةٍ وإيقافُها — للمدير وحدَه. لا يحذف صفَّ الصفة: يعمل بهويّة مديرٍ تُكتب في السطر أدناه.
-- كلُّه داخل begin … rollback. والاجتماعُ المفتوح تجهيزٌ يُكتب مباشرةً ثمّ يُلغى، داخل التراجع.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '20s';
-- ⇐ ضع هنا معرّفَ حسابِ مديرِ طُفيل (auth.users.id). وإن بقي فارغًا رجع كلُّ سطرٍ «لا هويّةَ مدير» ولم يُمسّ شيء.
select set_config('t.principal_uid', '', true);
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.p_saeed',(select person_id::text from v2.app_users where id='52bc11f6-8e82-44cd-9f4d-e9bf43aee128'),true);

set local role authenticated;
select set_config('request.jwt.claims', json_build_object('sub',nullif(current_setting('t.principal_uid'),''),'role','authenticated')::text, true);
do $$ declare s record; r text; begin
  if nullif(current_setting('t.principal_uid'),'') is not null then
    perform public.v2_act_as('principal', current_setting('t.school')::uuid);
  end if;
  for s in select * from (values
    (1, 'لجنةٌ بلا مقرّر', null::text, $q$select public.v2_committee_create('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,null,'لجنة فحص','غرض','[{"seat_role":"chair","post_key":"principal"},{"seat_role":"member","seat_count":3}]'::jsonb)::text$q$),
    (2, 'لجنةٌ بلا مقاعد', null::text, $q$select public.v2_committee_create('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,null,'لجنة فحص','غرض','[]'::jsonb)::text$q$),
    (3, 'لجنةٌ صحيحة', 'ck', $q$select public.v2_committee_create('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'test_fahs','لجنة فحص','غرض','[{"seat_role":"chair","post_key":"principal"},{"seat_role":"rapporteur","post_key":"counselor"},{"seat_role":"member","seat_count":3}]'::jsonb)->>'committee'$q$),
    (4, 'لجنةٌ بالمفتاح نفسه', null::text, $q$select public.v2_committee_create('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'test_fahs','لجنة فحص','غرض','[{"seat_role":"chair","post_key":"principal"},{"seat_role":"rapporteur","post_key":"counselor"},{"seat_role":"member","seat_count":3}]'::jsonb)::text$q$),
    (5, 'القائمةُ بعدها', null::text, $q$select 'للمدرسة '||(select count(*) from jsonb_array_elements(r) x where (x->>'mine')::boolean) from (select public.v2_committees_list('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid) r) z$q$),
    (6, 'يوقف لجنةَ التوجيه (وزاريّة)', null::text, $q$select public.v2_committee_close('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance','سبب')::text$q$),
    (7, 'يوقف لجنتَه بلا سبب', null::text, $q$select public.v2_committee_close('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.ck'),'  ')::text$q$)
  ) v(n,l,k,q) order by n loop
    if nullif(current_setting('t.principal_uid'),'') is null then r := 'لا هويّةَ مدير — لم يُشغَّل';
    else
      begin execute s.q into r;
        if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
        r := 'نفذ: '||coalesce(r,'—');
      exception when others then r := 'رُفض: '||sqlerrm; end;
    end if;
    perform set_config('t.s'||s.n, 'المدير · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- تجهيز: اجتماعٌ مفتوحٌ للجنة الجديدة
insert into v2.committee_meetings(school_id,committee_key,status,agenda_ar)
select current_setting('t.school')::uuid, current_setting('t.ck',true), 'مدعوّ إليه', 'تجهيزُ فحص'
 where nullif(current_setting('t.ck',true),'') is not null;

set local role authenticated;
select set_config('request.jwt.claims', json_build_object('sub',nullif(current_setting('t.principal_uid'),''),'role','authenticated')::text, true);
do $$ declare s record; r text; begin
  if nullif(current_setting('t.principal_uid'),'') is not null then
    perform public.v2_act_as('principal', current_setting('t.school')::uuid);
  end if;
  for s in select * from (values
    (8, 'يوقفها ولها اجتماعٌ مفتوح', null::text, $q$select public.v2_committee_close('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.ck'),'انتهى غرضُها')::text$q$)
  ) v(n,l,k,q) order by n loop
    if nullif(current_setting('t.principal_uid'),'') is null then r := 'لا هويّةَ مدير — لم يُشغَّل';
    else
      begin execute s.q into r;
        if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
        r := 'نفذ: '||coalesce(r,'—');
      exception when others then r := 'رُفض: '||sqlerrm; end;
    end if;
    perform set_config('t.s'||s.n, 'المدير · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- تجهيز: يُلغى الاجتماع
update v2.committee_meetings set status='ملغًى', cancel_reason='تجهيزُ فحص' where committee_key=nullif(current_setting('t.ck',true),'');

set local role authenticated;
select set_config('request.jwt.claims', json_build_object('sub',nullif(current_setting('t.principal_uid'),''),'role','authenticated')::text, true);
do $$ declare s record; r text; begin
  if nullif(current_setting('t.principal_uid'),'') is not null then
    perform public.v2_act_as('principal', current_setting('t.school')::uuid);
  end if;
  for s in select * from (values
    (9, 'يوقفها بعد إلغاء الاجتماع', null::text, $q$select public.v2_committee_close('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.ck'),'انتهى غرضُها')->>'note'$q$),
    (10, 'القائمةُ بعد الإيقاف', null::text, $q$select 'للمدرسة '||(select count(*) from jsonb_array_elements(r) x where (x->>'mine')::boolean) from (select public.v2_committees_list('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid) r) z$q$)
  ) v(n,l,k,q) order by n loop
    if nullif(current_setting('t.principal_uid'),'') is null then r := 'لا هويّةَ مدير — لم يُشغَّل';
    else
      begin execute s.q into r;
        if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
        r := 'نفذ: '||coalesce(r,'—');
      exception when others then r := 'رُفض: '||sqlerrm; end;
    end if;
    perform set_config('t.s'||s.n, 'المدير · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", left(current_setting('t.s'||n),500) as النتيجة from generate_series(1,10) n;
rollback;
