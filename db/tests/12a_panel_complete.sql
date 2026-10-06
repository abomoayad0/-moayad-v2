-- فحص ١٢أ (الإصدار ٢، بعد الإصلاحات الخمسة) · الهويّةُ البصريّة ورفعُ صورها · التقويمُ والفصول · الهيكل · الاستثناءات · المراجع · النصاب.
-- كلُّه داخل begin … rollback. والمخزنُ يُكتب فيه داخل التراجع أيضًا فلا يبقى ملفّ (صفُّ storage.objects وحدَه، بلا محتوى).
-- لا يُنشئ حسابًا ولا يمسّ كلمةَ مرور، ولا يحذف صفَّ الصفة. والهويّات: سعيد بصفة الموجّه · مفرح بصفة وكيل شؤون الطلاب.
-- وما هو للمدير وحدَه في 12b (ينتظر هويّةَ مدير).
begin;
set local lock_timeout = '5s';
set local statement_timeout = '20s';

select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.year',(select id::text from v2.academic_years where school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid and is_current),true),
       set_config('t.p_me',(select person_id::text from v2.app_users where id='11be0946-ff39-4eb7-8a74-023b580479be'),true),
       set_config('t.p_saeed',(select person_id::text from v2.app_users where id='52bc11f6-8e82-44cd-9f4d-e9bf43aee128'),true);

-- الموجّه
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; t0 timestamptz; begin
  for s in select * from (values
    (1, 'يضبط الهويّةَ البصريّة', null::text, $q$select public.v2_brand_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,null,null,null,'#112233',null,null,null)::text$q$),
    (2, 'يقيّد استثناءً بسببٍ مكتوب', null::text, $q$select public.v2_exception_add('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'other',null,'كذا','كذا','سبب',null)::text$q$),
    (3, 'يقرأ سجلَّ الاستثناءات', null::text, $q$select public.v2_exceptions_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid)::text$q$),
    (4, 'مسارُ رفع شعار', null::text, $q$select public.v2_brand_upload_path('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'logo','png')::text$q$),
    (5, 'مسارُ رفع توقيعه', 'sg_c', $q$select public.v2_brand_upload_path('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'sign','png')->>'path'$q$),
    (6, 'يرفع توقيعَه إلى المسار', null::text, $q$insert into storage.objects(bucket_id,name) values ('v2-attachments',current_setting('t.sg_c')) returning name$q$)
  ) v(n,l,k,q) order by n loop
    t0 := clock_timestamp();
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الموجّه · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- الوكيل
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; t0 timestamptz; begin
  for s in select * from (values
    (7, 'ختمٌ للمدرسة', null::text, $q$select public.v2_stamp_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'brand/'||current_setting('t.school')||'/stamp/x.png',null)::text$q$),
    (8, 'مسارُ رفع شعار', 'logo', $q$select public.v2_brand_upload_path('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'logo','PNG')->>'path'$q$),
    (9, 'نوعُ مسارٍ مجهول', null::text, $q$select public.v2_brand_upload_path('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'photo','png')::text$q$),
    (10, 'يرفع الشعارَ إلى المسار', null::text, $q$insert into storage.objects(bucket_id,name) values ('v2-attachments',current_setting('t.logo')) returning name$q$),
    (11, 'يرفع إلى مسار مدرسةٍ غيرِ مدرسته', null::text, $q$insert into storage.objects(bucket_id,name) values ('v2-attachments','brand/00000000-0000-0000-0000-0000000000aa/logo/x.png') returning name$q$),
    (12, 'يحفظ الهويّةَ بالشعار والترويسة', null::text, $q$select public.v2_brand_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.logo'),'center',true,'#0A5C36','#C9A227','ترويسة فحص','تذييل فحص')->>'ok'$q$),
    (13, 'يمحو الترويسة (p_clear)', null::text, $q$select public.v2_brand_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,null,null,null,null,null,null,null,array['header_ar'])->>'ok'$q$),
    (14, 'يمحو حقلًا غيرَ مسموح', null::text, $q$select public.v2_brand_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,null,null,null,null,null,null,null,array['school_id'])::text$q$),
    (15, 'البطاقةُ بعدهما', null::text, $q$select 'شعار='||coalesce(r->'brand'->>'logo_path','—')||' · ترويسة='||coalesce(r->'brand'->>'header_ar','ممحوّة')||' · تذييل='||coalesce(r->'brand'->>'footer_ar','—')||' · مفاتيح: '||(select string_agg(k,',' order by k) from jsonb_object_keys(r) k) from (select public.v2_brand_card('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid) r) z$q$),
    (16, 'مسارُ رفع توقيعه', 'sg_m', $q$select public.v2_brand_upload_path('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'sign','png')->>'path'$q$),
    (17, 'يرفع توقيعَه', null::text, $q$insert into storage.objects(bucket_id,name) values ('v2-attachments',current_setting('t.sg_m')) returning name$q$),
    (18, 'توقيعُه بالمسار', null::text, $q$select public.v2_signature_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.p_me')::uuid,current_setting('t.sg_m'),current_date)->>'ok'$q$),
    (19, 'توقيعٌ ثانٍ له في اليوم نفسه', null::text, $q$select public.v2_signature_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.p_me')::uuid,current_setting('t.sg_m'),current_date)::text$q$),
    (20, 'توقيعٌ بصورةٍ خارجَ مسار المدرسة', null::text, $q$select public.v2_signature_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.p_me')::uuid,'x/y.png',current_date+1)::text$q$),
    (21, 'توقيعُ غيره (سعيد)', null::text, $q$select public.v2_signature_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.p_saeed')::uuid,current_setting('t.sg_m'),current_date)::text$q$),
    (22, 'استثناءٌ (من غير المدير)', null::text, $q$select public.v2_exception_add('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'other',null,'كذا','كذا','سبب',null)::text$q$),
    (23, 'أنواعُ الاستثناء', null::text, $q$select jsonb_array_length(r)||': '||(select string_agg(x->>'key',' · ') from jsonb_array_elements(r) x) from (select public.v2_exception_kinds() r) z$q$),
    (24, 'يغيّر الهيكل', null::text, $q$select public.v2_structure_set('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'s3')::text$q$),
    (25, 'لوحةُ الهيكل', null::text, $q$select 'النافذ='||coalesce(r->'current'->>'code','لا شيء')||' · '||(select string_agg((h->>'code')||':'||(h->>'orphans'),' ' order by h->>'code') from jsonb_array_elements(r->'all') h)||' · خارجَه الآن: '||(select string_agg(o->>'label',' · ') from jsonb_array_elements(r->'outside') o) from (select public.v2_structure_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid) r) z$q$),
    (26, 'سنةٌ جديدةٌ جارية (١٤٤٩)', 'y2', $q$select public.v2_year_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,null,'1449هـ فحص','2027-08-22','2028-06-10',true)->>'year'$q$),
    (27, 'الجاريةُ في لوحة التقويم', null::text, $q$select string_agg((y->>'name')||'='||(y->>'current'),' · ') from jsonb_array_elements(public.v2_calendar_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid)->'years') y$q$),
    (28, 'ثمّ تُعاد الحاليّةُ جارية', null::text, $q$select public.v2_year_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.year')::uuid,(r->>'name'),(r->>'starts')::date,(r->>'ends')::date,true)->>'ok' from (select y r from jsonb_array_elements(public.v2_calendar_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid)->'years') y where y->>'year'=current_setting('t.year')) z$q$),
    (29, 'فصلٌ أوّلُ جارٍ', 't1', $q$select public.v2_term_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.year')::uuid,null,1::smallint,'2026-08-23','2026-12-31',true)->>'term'$q$),
    (30, 'فصلٌ ثانٍ يتداخل', null::text, $q$select public.v2_term_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.year')::uuid,null,2::smallint,'2026-12-01','2027-03-01',false)::text$q$),
    (31, 'فصلٌ ثانٍ خارجَ سنته', null::text, $q$select public.v2_term_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.year')::uuid,null,2::smallint,'2027-01-03','2027-07-01',false)::text$q$),
    (32, 'فصلٌ ثانٍ جارٍ', 't2', $q$select public.v2_term_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.year')::uuid,null,2::smallint,'2027-01-03','2027-06-10',true)->>'term'$q$),
    (33, 'الجاريةُ والجاري في اللوحة', null::text, $q$select string_agg((y->>'name')||'='||(y->>'current')||' ['||(select string_agg((t->>'no')||':'||(t->>'current'),',') from jsonb_array_elements(y->'terms') t)||']',' · ') from jsonb_array_elements(public.v2_calendar_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid)->'years') y$q$),
    (34, 'تقصيرُ السنة حتى يخرج الفصلُ الثاني', null::text, $q$select public.v2_year_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.year')::uuid,'1448هـ','2026-08-23','2027-03-01',null)::text$q$),
    (35, 'تعديلُ الفصل الثاني إلى رقمٍ مكرَّر', null::text, $q$select public.v2_term_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.year')::uuid,current_setting('t.t2')::uuid,1::smallint,'2027-01-03','2027-06-10',null)::text$q$)
  ) v(n,l,k,q) order by n loop
    t0 := clock_timestamp();
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الوكيل · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- إقفالُ السنة الجديدة (تجهيزٌ داخل التراجع — لا جسرَ للإقفال)
update v2.academic_years set status='closed', closed_on=current_date where id=nullif(current_setting('t.y2',true),'')::uuid;

-- الوكيل
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
do $$ declare s record; r text; t0 timestamptz; begin
  for s in select * from (values
    (36, 'تعديلُ سنةٍ مقفلة', null::text, $q$select public.v2_year_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.y2')::uuid,'1449هـ معدّلة','2027-08-22','2028-06-10',null)::text$q$),
    (37, 'فصلٌ في سنةٍ مقفلة', null::text, $q$select public.v2_term_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.y2')::uuid,null,1::smallint,'2027-08-22','2027-12-31',false)::text$q$),
    (38, 'مرجعٌ بمفتاحٍ مجهول', null::text, $q$select public.v2_reference('rules')::text$q$),
    (39, 'المراجعُ الأربعة', null::text, $q$select string_agg(k||'='||coalesce(jsonb_array_length(public.v2_reference(k)->'items'),jsonb_array_length(public.v2_reference(k)->'models')),' · ') from unnest(array['absence_ladder','absence_excuses','violence_types','grading']) k$q$),
    (40, 'مجلسُ لجنة التوجيه', null::text, $q$select (r->'committee'->>'quorum_ar')||' · mode='||(r->'committee'->>'quorum_mode')||' · مهامّ '||jsonb_array_length(r->'duties') from (select public.v2_committee_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance') r) z$q$)
  ) v(n,l,k,q) order by n loop
    t0 := clock_timestamp();
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
do $$ declare s record; r text; t0 timestamptz; begin
  for s in select * from (values
    (41, '(من الكود) يستبدل ملفَّ توقيع غيره في المخزن', null::text, $q$update storage.objects set metadata=coalesce(metadata,'{}'::jsonb) where bucket_id='v2-attachments' and name=current_setting('t.sg_m') returning name$q$),
    (42, '(من الكود) يحفظ توقيعَه بصورة غيره', null::text, $q$select public.v2_signature_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.p_saeed')::uuid,current_setting('t.sg_m'),current_date)->>'ok'$q$)
  ) v(n,l,k,q) order by n loop
    t0 := clock_timestamp();
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الموجّه · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", left(current_setting('t.s'||n),500) as النتيجة from generate_series(1,42) n;

rollback;
