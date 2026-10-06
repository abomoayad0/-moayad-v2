-- فحص ١٢ب · ما هو للمدير وحدَه في الهويّة البصريّة والاستثناءات والهيكل. لا يحذف صفَّ الصفة: يعمل بهويّة مديرٍ تُكتب في السطر أدناه.
-- كلُّه داخل begin … rollback، والمخزنُ داخله.
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
    (1, 'مسارُ ختم', 'st_a', $q$select public.v2_brand_upload_path('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'stamp','png')->>'path'$q$),
    (2, 'يرفع الختم', null::text, $q$insert into storage.objects(bucket_id,name) values ('v2-attachments',current_setting('t.st_a')) returning name$q$),
    (3, 'ختمٌ يسري من عشرة أيّام', 'st1', $q$select public.v2_stamp_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.st_a'),current_date-10)->>'stamp'$q$),
    (4, 'ختمٌ جديدٌ اليوم', 'st2', $q$select public.v2_stamp_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.st_a'),null)->>'stamp'$q$),
    (5, 'البطاقة: الجاري والسابق', null::text, $q$select 'الجاري الجديد='||((r->'stamp'->>'id')=current_setting('t.st2'))::text||' · السابقُ '||jsonb_array_length(r->'stamps_past')||coalesce(' انتهى '||(r->'stamps_past'->0->>'to'),'') from (select public.v2_brand_card('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid) r) z$q$),
    (6, 'ختمٌ ثانٍ في اليوم نفسه', null::text, $q$select public.v2_stamp_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.st_a'),null)::text$q$),
    (7, 'ختمٌ يبدأ بعد شهر', null::text, $q$select public.v2_stamp_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.st_a'),current_date+30)->>'ok'$q$),
    (8, 'البطاقة: الجاري والقادم', null::text, $q$select 'الجاري الجديد='||((r->'stamp'->>'id')=current_setting('t.st2'))::text||' · القادمُ من '||coalesce(r->'stamp_next'->>'from','—') from (select public.v2_brand_card('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid) r) z$q$),
    (9, 'مسارُ توقيع', 'sg', $q$select public.v2_brand_upload_path('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'sign','png')->>'path'$q$),
    (10, 'يرفع التوقيع', null::text, $q$insert into storage.objects(bucket_id,name) values ('v2-attachments',current_setting('t.sg')) returning name$q$),
    (11, 'توقيعُ غيره (سعيد)', null::text, $q$select public.v2_signature_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.p_saeed')::uuid,current_setting('t.sg'),current_date)->>'ok'$q$),
    (12, 'استثناءٌ بلا سبب', null::text, $q$select public.v2_exception_add('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'staffing',null,'وكيلان','وكيل','  ',null)::text$q$),
    (13, 'استثناءٌ بسبب (staffing)', null::text, $q$select public.v2_exception_add('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'staffing','posts','وكيلان','وكيل','نقصُ الملاك','ص١٢')->>'ok'$q$),
    (14, '(من الكود) استثناءٌ بنوعٍ من v2_exception_kinds (conduct)', null::text, $q$select public.v2_exception_add('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'conduct',null,'كذا','كذا','سبب',null)::text$q$),
    (15, 'سجلُّ الاستثناءات', null::text, $q$select jsonb_array_length(r)||' · قرّره '||coalesce(r->0->>'decided_by','—') from (select public.v2_exceptions_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid) r) z$q$),
    (16, 'هيكلٌ يترك مكلَّفًا خارجَه (s0)', null::text, $q$select public.v2_structure_set('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'s0')::text$q$),
    (17, 'هيكلٌ غيرُ موجود', null::text, $q$select public.v2_structure_set('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'s9')::text$q$)
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

select n::text as "#", left(current_setting('t.s'||n),500) as النتيجة from generate_series(1,17) n;
rollback;
