-- فحص ١٢ (ب) · أبوابُ اللوحة الجديدة: الهويّةُ البصريّة · التقويمُ والفصول · الهيكلُ التنظيميّ · المراجعُ الأربعة · سجلُّ الاستثناءات · النصاب.
-- فيه الفحوصُ التسعةُ المطلوبة، وما كشفته قراءةُ الكود. كلُّه داخل begin … rollback.
-- لا يُنشئ حسابًا ولا يمسّ كلمةَ مرور، ولا يرفع ملفًّا (محاولةُ الكتابة في المخزن تُرفض أو تُلغى بالتراجع).
-- الهويّات: سعيد بصفة الموجّه · مفرح بصفة وكيل شؤون الطلاب · ومفرح بمنحة «المالك» بلا صفةٍ مختارة.
-- ⚠️ لا هويّةَ فحصٍ تحمل تكليفَ «مدير». فما هو للمدير وحدَه جُرّب نافذًا بالمالك (assert_role يُمرّر owner/admin حين لا صفةَ مختارة)،
--    وجُرّب مرفوضًا بالوكيل. ولتجربة المالك بلا صفة يُحذف صفُّ صفته المختارة (session_role) داخل التراجع.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '20s';

select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.year',(select id::text from v2.academic_years where school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid and is_current),true),
       set_config('t.p_me',(select person_id::text from v2.app_users where id='11be0946-ff39-4eb7-8a74-023b580479be'),true),
       set_config('t.p_saeed',(select person_id::text from v2.app_users where id='52bc11f6-8e82-44cd-9f4d-e9bf43aee128'),true),
       set_config('t.code_orphan',(select st.code from v2.structures st order by (select count(distinct a.post_key) from v2.assignments a where a.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid and a.ended_on is null
           and not exists (select 1 from v2.structure_posts sp where sp.structure_code=st.code and sp.post_key=a.post_key)) desc, st.code limit 1),true),
       set_config('t.code_ok',coalesce((select st.code from v2.structures st where not exists (select 1 from v2.assignments a where a.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid and a.ended_on is null
           and not exists (select 1 from v2.structure_posts sp where sp.structure_code=st.code and sp.post_key=a.post_key)) order by st.code limit 1),''),true),
       set_config('t.struct_before',coalesce((select structure_code from v2.schools where id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid),'null'),true);

-- المالك بلا صفةٍ مختارة: يُحذف صفُّ صفته المختارة داخل التراجع
delete from v2.session_role where user_id='11be0946-ff39-4eb7-8a74-023b580479be';

-- المالك
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
do $$ declare s record; r text; t0 timestamptz; begin
  for s in select * from (values
    (42, 'ختمٌ أوّلُ (من عشرة أيّام)', 'st1', $q$select public.v2_stamp_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'stamps/a.png',current_date-10)->>'stamp'$q$),
    (43, 'ختمٌ جديد (اليوم)', 'st2', $q$select public.v2_stamp_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'stamps/b.png',null)->>'stamp'$q$),
    (44, 'السابقُ بعده', null::text, $q$select 'باقٍ='||count(*)||' · انتهى في '||coalesce(max(valid_to)::text,'—')||' · الجاري هو الجديد='||(select (id=current_setting('t.st2')::uuid)::text from v2.stamps where school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid and valid_to is null) from v2.stamps where id=current_setting('t.st1')::uuid$q$),
    (45, 'البطاقةُ تعرض الختمَ السابق؟', null::text, $q$select 'الختمُ في البطاقة='||case (r->'stamp'->>'id') when current_setting('t.st2') then 'الجديد' when current_setting('t.st1') then 'السابق' else coalesce(r->'stamp'->>'id','لا') end||' · فيها مفتاحٌ للسابق='||(r ? 'stamps' or r ? 'stamp_history')::text from (select public.v2_brand_card('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid) r) z$q$),
    (46, '(من الكود) ختمٌ ثالثٌ في اليوم نفسه', null::text, $q$select public.v2_stamp_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'stamps/c.png',null)::text$q$),
    (47, '(من الكود) ختمٌ يبدأ بعد شهر', null::text, $q$select public.v2_stamp_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'stamps/d.png',current_date+30)->>'ok'$q$),
    (48, 'توقيعُ غيره (سعيد) — بالمالك', null::text, $q$select public.v2_signature_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.p_saeed')::uuid,'sig/s.png',current_date)->>'ok'$q$),
    (49, 'استثناءٌ بلا سبب', null::text, $q$select public.v2_exception_add('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'staffing',null,'وكيلان','وكيلٌ واحد','  ',null)::text$q$),
    (50, 'استثناءٌ بسببٍ مكتوب', 'ex1', $q$select public.v2_exception_add('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'staffing','posts','وكيلان للمدرسة','وكيلٌ واحد','نقصُ الملاك هذا العام','الدليل التنظيمي ص١٢')->>'exception'$q$),
    (51, '(من الكود) استثناءٌ بلا نوع', null::text, $q$select public.v2_exception_add('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,null,null,'كذا','كذا','سبب',null)::text$q$),
    (52, 'سجلُّ الاستثناءات', null::text, $q$select jsonb_array_length(r)||' · قرّره '||coalesce(r->0->>'decided_by','—')||' · '||(r->0->>'rule_kind')||' · سببه: '||(r->0->>'reason') from (select public.v2_exceptions_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid) r) z$q$),
    (53, 'هيكلٌ يترك مكلَّفًا خارجَه', null::text, $q$select public.v2_structure_set('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.code_orphan'))::text$q$),
    (54, 'هيكلٌ يسع المكلَّفين', null::text, $q$select case when current_setting('t.code_ok')='' then 'لا هيكلَ يسع مكلَّفي طفيل كلَّهم' else public.v2_structure_set('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.code_ok'))::text end$q$),
    (55, 'هيكلٌ غيرُ موجودٍ في الدليل', null::text, $q$select public.v2_structure_set('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'s9')::text$q$),
    (56, 'لوحةُ الهيكل بعد ضبطه', null::text, $q$select 'النافذ='||coalesce(r->'current'->>'code','لا شيء')||' · وظائف '||jsonb_array_length(r->'posts')||' · مشغولة '||(select count(*) from jsonb_array_elements(r->'posts') p where (p->>'filled')::int>0) from (select public.v2_structure_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992') r) z$q$),
    (57, '(من الكود) الختمُ الذي تعرضه البطاقةُ بعد الختم المؤجَّل', null::text, $q$select 'يبدأ '||(r->'stamp'->>'from')||' · واليومُ '||current_date||' · صورته '||(r->'stamp'->>'image') from (select public.v2_brand_card('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid) r) z$q$),
    (58, '(من الكود) توقيعٌ ثانٍ لسعيد في اليوم نفسه', null::text, $q$select public.v2_signature_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.p_saeed')::uuid,'sig/s2.png',current_date)::text$q$)
  ) v(n,l,k,q) order by n loop
    t0 := clock_timestamp();
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, '['||round(extract(epoch from clock_timestamp()-t0)*1000)||'ms] '||'المالك · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", left(current_setting('t.s'||n),500) as النتيجة from generate_series(42,58) n
union all select 'أ', 'الهيكلُ قبل الفحص: '||current_setting('t.struct_before')||' · المرشَّحُ للرفض: '||current_setting('t.code_orphan')||' · المرشَّحُ للقبول: '||coalesce(nullif(current_setting('t.code_ok'),''),'لا شيء')
union all select 'ب', 'أختامُ طفيل الآن (داخل التراجع): '||(select string_agg(image_ref||' '||valid_from||'→'||coalesce(valid_to::text,'∞'),' · ' order by valid_from) from v2.stamps where school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992');

rollback;
