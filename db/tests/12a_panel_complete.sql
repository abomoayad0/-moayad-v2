-- فحص ١٢ (أ) · أبوابُ اللوحة الجديدة: الهويّةُ البصريّة · التقويمُ والفصول · الهيكلُ التنظيميّ · المراجعُ الأربعة · سجلُّ الاستثناءات · النصاب.
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

-- الموجّه
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; t0 timestamptz; begin
  for s in select * from (values
    (1, 'يضبط الهويّةَ البصريّة', null::text, $q$select public.v2_brand_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,null,null,null,'#112233',null,null,null)::text$q$),
    (2, 'يقيّد استثناءً بسببٍ مكتوب', null::text, $q$select public.v2_exception_add('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'other',null,'كذا','كذا','سبب',null)::text$q$),
    (3, 'يقرأ سجلَّ الاستثناءات', null::text, $q$select public.v2_exceptions_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid)::text$q$),
    (4, 'يقرأ مرجعَ أعذار الغياب', null::text, $q$select 'بنود '||jsonb_array_length(r->'items')||' · locked='||(r->>'locked') from (select public.v2_reference('absence_excuses') r) z$q$)
  ) v(n,l,k,q) order by n loop
    t0 := clock_timestamp();
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, '['||round(extract(epoch from clock_timestamp()-t0)*1000)||'ms] '||'الموجّه · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- الوكيل
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; t0 timestamptz; begin
  for s in select * from (values
    (5, 'ختمٌ للمدرسة', null::text, $q$select public.v2_stamp_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'stamps/x.png',null)::text$q$),
    (6, 'توقيعُه هو', null::text, $q$select public.v2_signature_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.p_me')::uuid,'sig/me.png',current_date)->>'ok'$q$),
    (7, 'توقيعُ غيره (سعيد)', null::text, $q$select public.v2_signature_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.p_saeed')::uuid,'sig/s.png',current_date)::text$q$),
    (8, 'استثناءٌ بسببٍ مكتوب (من غير المدير)', null::text, $q$select public.v2_exception_add('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'other',null,'كذا','كذا','سبب',null)::text$q$),
    (9, 'يغيّر الهيكل', null::text, $q$select public.v2_structure_set('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.code_ok'))::text$q$),
    (10, 'لونٌ بغير صيغة #RRGGBB', null::text, $q$select public.v2_brand_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,null,null,null,'red',null,null,null)::text$q$),
    (11, 'موضعُ شعارٍ مجهول', null::text, $q$select public.v2_brand_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,null,'top',null,null,null,null,null)::text$q$),
    (12, 'هويّةٌ صحيحة', null::text, $q$select public.v2_brand_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,null,'center',true,'#0A5C36','#C9A227','ترويسة فحص','تذييل فحص')->>'ok'$q$),
    (13, 'سنةٌ جديدةٌ جارية (١٤٤٩)', null::text, $q$select public.v2_year_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,null,'1449هـ فحص','2027-08-22','2028-06-10',true)->>'year'$q$),
    (14, 'سنةٌ جديدةٌ غيرُ جارية (١٤٤٩)', 'y2', $q$select public.v2_year_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,null,'1449هـ فحص','2027-08-22','2028-06-10',false)->>'year'$q$),
    (15, 'ثمّ جعلُها الجارية', null::text, $q$select public.v2_year_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.y2')::uuid,'1449هـ فحص','2027-08-22','2028-06-10',true)->>'ok'$q$),
    (16, 'السنواتُ الجاريةُ بعدها', null::text, $q$select count(*)||' · والجاريةُ هي الحاليّة='||bool_and(id=current_setting('t.year')::uuid) from v2.academic_years where school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid and is_current$q$),
    (17, 'فصلٌ أوّلُ في السنة الحاليّة', 't1', $q$select public.v2_term_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.year')::uuid,null,1::smallint,'2026-08-23','2026-12-31',true)->>'term'$q$),
    (18, 'فصلٌ ثانٍ يتداخل مع الأوّل', null::text, $q$select public.v2_term_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.year')::uuid,null,2::smallint,'2026-12-01','2027-03-01',false)::text$q$),
    (19, 'فصلٌ ثانٍ خارجَ حدود سنته', null::text, $q$select public.v2_term_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.year')::uuid,null,2::smallint,'2027-01-03','2027-07-01',false)::text$q$),
    (20, 'فصلٌ ثانٍ صحيحٌ جارٍ', null::text, $q$select public.v2_term_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.year')::uuid,null,2::smallint,'2027-01-03','2027-06-10',true)->>'term'$q$),
    (21, 'فصلٌ ثانٍ صحيحٌ غيرُ جارٍ', 't2', $q$select public.v2_term_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.year')::uuid,null,2::smallint,'2027-01-03','2027-06-10',false)->>'term'$q$),
    (22, 'ثمّ جعلُه الجاري', null::text, $q$select public.v2_term_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.year')::uuid,current_setting('t.t2')::uuid,2::smallint,'2027-01-03','2027-06-10',true)->>'ok'$q$),
    (23, 'الفصولُ الجاريةُ بعده', null::text, $q$select count(*)||' · والجاري هو الأوّل='||bool_and(id=current_setting('t.t1')::uuid) from v2.terms where year_id=current_setting('t.year')::uuid and is_current$q$),
    (24, '(من الكود) تقصيرُ السنة حتى يخرج الفصلُ الثاني عنها', null::text, $q$select public.v2_year_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.year')::uuid,(select name from v2.academic_years where id=current_setting('t.year')::uuid),'2026-08-23','2027-03-01',null)->>'ok'$q$),
    (25, '(من الكود) فصلٌ رقمُه مكرَّرٌ عند التعديل', null::text, $q$select public.v2_term_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.year')::uuid,current_setting('t.t2')::uuid,1::smallint,'2027-01-03','2027-02-28',null)::text$q$)
  ) v(n,l,k,q) order by n loop
    t0 := clock_timestamp();
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, '['||round(extract(epoch from clock_timestamp()-t0)*1000)||'ms] '||'الوكيل · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- إقفالُ السنة الجديدة (تجهيزٌ داخل التراجع — لا جسرَ للإقفال في هذي الأبواب)
update v2.academic_years set status='closed', closed_on=current_date where id=nullif(current_setting('t.y2',true),'')::uuid;

-- الوكيل
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
do $$ declare s record; r text; t0 timestamptz; begin
  for s in select * from (values
    (26, 'تعديلُ سنةٍ مقفلة', null::text, $q$select public.v2_year_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.y2')::uuid,'1449هـ معدّلة','2027-08-22','2028-06-10',null)::text$q$),
    (27, 'فصلٌ في سنةٍ مقفلة', null::text, $q$select public.v2_term_save('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,current_setting('t.y2')::uuid,null,1::smallint,'2027-08-22','2027-12-31',false)::text$q$),
    (28, 'لوحةُ التقويم', null::text, $q$select 'المسار='||coalesce(r->'scope'->>'label','—')||' · مساراتٌ '||jsonb_array_length(r->'scopes')||' · سنواتٌ '||jsonb_array_length(r->'years')||' · فصولُ الحاليّة '||(select jsonb_array_length(y->'terms') from jsonb_array_elements(r->'years') y where y->>'year'=current_setting('t.year'))||' · طلّابُها '||(select y->>'students' from jsonb_array_elements(r->'years') y where y->>'year'=current_setting('t.year')) from (select public.v2_calendar_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992') r) z$q$),
    (29, 'لوحةُ الهيكل', null::text, $q$select 'النافذ='||coalesce(r->'current'->>'code','لا شيء')||' · الهياكل '||jsonb_array_length(r->'all')||' · وظائف '||jsonb_array_length(r->'posts') from (select public.v2_structure_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992') r) z$q$),
    (30, 'بطاقةُ الهويّة', null::text, $q$select 'موضع='||(r->'brand'->>'logo_position')||' · لون='||(r->'brand'->>'primary_color')||' · ختم='||coalesce(r->'stamp'->>'id','لا')||' · تواقيع '||jsonb_array_length(r->'signatures') from (select public.v2_brand_card('7a847bb1-9b14-41ad-b9ba-7c8dee61a992') r) z$q$),
    (31, 'بطاقةُ هويّة مدرسةٍ ليست له', null::text, $q$select public.v2_brand_card('00000000-0000-0000-0000-0000000000aa')::text$q$),
    (32, 'مرجعٌ بمفتاحٍ مجهول', null::text, $q$select public.v2_reference('rules')::text$q$),
    (33, 'مرجع سلّم الغياب', null::text, $q$select 'بنود '||jsonb_array_length(r->'items')||' · locked='||(r->>'locked')||' · '||(r->>'source') from (select public.v2_reference('absence_ladder') r) z$q$),
    (34, 'مرجع أعذار الغياب', null::text, $q$select 'بنود '||jsonb_array_length(r->'items')||' · تقديرُ المدرسة '||(select count(*) from jsonb_array_elements(r->'items') i where (i->>'school_discretion')::boolean)||' · locked='||(r->>'locked') from (select public.v2_reference('absence_excuses') r) z$q$),
    (35, 'مرجع أنواع العنف', null::text, $q$select 'أنواع '||jsonb_array_length(r->'items')||' · locked='||(r->>'locked')||' · '||(r->>'source') from (select public.v2_reference('violence_types') r) z$q$),
    (36, 'مرجع التقدير', null::text, $q$select 'نماذج '||jsonb_array_length(r->'models')||' · مواد '||jsonb_array_length(r->'subjects')||' · locked='||(r->>'locked') from (select public.v2_reference('grading') r) z$q$),
    (37, 'قواعدُ لجنة التوجيه', null::text, $q$select 'mode='||(r->>'quorum_mode')||' · min='||coalesce(r->>'quorum_min','null')||' · seated='||(r->>'seated')||' · '||(r->>'quorum_ar')||' · remote='||(r->>'allow_remote')||' · tie='||(r->>'tie_rule') from (select public.v2_committee_rules_get('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance') r) z$q$),
    (38, 'نصابٌ بوضعٍ مجهول', null::text, $q$select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance',null,true,'رئيس',null,'half')::text$q$),
    (39, 'نصابٌ ثابتٌ بلا عدد', null::text, $q$select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance',null,true,'رئيس',null,'fixed')::text$q$),
    (40, '(من الكود) رفعُ صورة الشعار إلى المخزن', null::text, $q$insert into storage.objects(bucket_id,name) values ('v2-attachments','brand/'||'7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid||'/logo-test.png') returning name$q$),
    (41, 'محوُ الاستثناءات مباشرةً', null::text, $q$with d as (delete from v2.exceptions where school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid returning 1) select count(*)::text from d$q$)
  ) v(n,l,k,q) order by n loop
    t0 := clock_timestamp();
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, '['||round(extract(epoch from clock_timestamp()-t0)*1000)||'ms] '||'الوكيل · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", left(current_setting('t.s'||n),500) as النتيجة from generate_series(1,41) n
union all select 'ج', 'السنةُ الحاليّة بعد تقصيرها: '||(select starts_on||' → '||ends_on from v2.academic_years where id=current_setting('t.year')::uuid)||' · وفصولُها: '||(select string_agg(number||': '||starts_on||' → '||ends_on,' · ' order by number) from v2.terms where year_id=current_setting('t.year')::uuid);

rollback;
