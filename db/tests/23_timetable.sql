-- فحص ٢٣ · جدولُ الحصص: التحكّم والنصاب والخطّة والتوزيعُ الآليّ — بالنداءات التي ترسلها jadwal.js.
-- كلُّه داخل begin … rollback، فلا يبقى في الجدول ولا في المقترحات شيء.
-- ⚠️ أسماءُ الإعدادات لا تفرّق بين الحروف: كانت t.S1 و t.S2 تتصادم مع نتائج t.s1 و t.s2 في الإصدار ٢ — فسُمّيت t.sec1 · t.sec2 · t.ta · t.tb · t.per.
-- الإصدار ٣: أُصلحت الجسورُ (الأيّامُ ٠–٤ · weekday_ar لا يُكتب · days {no,label} · sections · حارسُ مدرسة draft_card · applied_by · إلغاءٌ بسبب) — فأُعيد مرّةً.
-- الهويّة: مفرح. وتكليفُه وكيلُ شؤون الطلاب يملك الحصّةَ وحدَها؛ والنصابُ والخطّةُ والاقتراحُ والإقرارُ للمدير والوكيل ووكيل الشؤون التعليميّة.
-- فيُضاف له داخل التراجع تكليفٌ مؤقّتٌ «وكيل المدرسة» في الطفيل (صفٌّ في assignments) — لا حسابَ يُمسّ، ولا حذف، ويزول بالتراجع.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '30s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.malik','f789f9ea-e474-49bc-86e0-3449258815f8',true),
       set_config('t.mof',(select person_id::text from v2.app_users where id='11be0946-ff39-4eb7-8a74-023b580479be'),true);
-- حصّةُ تدريسٍ قائمة: معلّمُها A وفصلُها S1 ووقتُها — وفصلٌ آخرُ S2 ومعلّمٌ آخرُ B
select set_config('t.x',(select t.id::text from v2.timetable t where t.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid
          and t.slot_kind='teaching' and t.person_id is not null and t.section_id is not null order by t.weekday, t.period_no limit 1),true);
select set_config('t.wd',(select weekday::text from v2.timetable where id=current_setting('t.x')::uuid),true),
       set_config('t.per',(select period_no::text from v2.timetable where id=current_setting('t.x')::uuid),true),
       set_config('t.ta',(select person_id::text from v2.timetable where id=current_setting('t.x')::uuid),true),
       set_config('t.sec1',(select section_id::text from v2.timetable where id=current_setting('t.x')::uuid),true);
select set_config('t.sec2',(select t.section_id::text from v2.timetable t where t.school_id=current_setting('t.school')::uuid
          and t.section_id is not null and t.section_id<>current_setting('t.sec1')::uuid
          and not exists (select 1 from v2.timetable y where y.section_id=t.section_id and y.weekday=current_setting('t.wd')::smallint and y.period_no=current_setting('t.per')::smallint)
          limit 1),true);
select set_config('t.tb',(select t.person_id::text from v2.timetable t where t.school_id=current_setting('t.school')::uuid
          and t.person_id is not null and t.person_id<>current_setting('t.ta')::uuid
          and not exists (select 1 from v2.timetable y where y.person_id=t.person_id and y.weekday=current_setting('t.wd')::smallint and y.period_no=current_setting('t.per')::smallint)
          limit 1),true);
select set_config('t.other',(select a.person_id::text from v2.assignments a where a.school_id=current_setting('t.malik')::uuid and a.ended_on is null
          and not exists (select 1 from v2.assignments b where b.person_id=a.person_id and b.school_id=current_setting('t.school')::uuid and b.ended_on is null)
          limit 1),true);

-- ① مفرح بصفة وكيل شؤون الطلاب — الحصّةُ وحرّاسُها
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'الجدول: الحصص · الأيّام · الفصول · الخانات · الحمل', null::text, $q$select jsonb_array_length(r->'periods')||' حصص · '||jsonb_array_length(r->'days')||' أيّام '||(r->'days'->0)::text||'…'||(r->'days'->4)::text||' · '||jsonb_array_length(r->'sections')||' فصلًا · '||jsonb_array_length(r->'slots')||' خانة · حملُ '||jsonb_array_length(r->'load')||' معلّمًا ‖ '||(r->'load'->0)::text from (select public.v2_timetable_board(current_setting('t.school')::uuid,null,null,null) r) z$q$),
    (2, 'فحص: المعلّمُ A في فصلٍ آخرَ S2 في وقته', null, $q$select public.v2_slot_check(current_setting('t.school')::uuid,null,current_setting('t.wd')::smallint,current_setting('t.per')::smallint,current_setting('t.sec2')::uuid,current_setting('t.ta')::uuid,'teaching')::text$q$),
    (3, 'حفظُه بلا إقرار', null, $q$select public.v2_slot_save(current_setting('t.school')::uuid,null,current_setting('t.wd')::smallint,current_setting('t.per')::smallint,current_setting('t.sec2')::uuid,current_setting('t.ta')::uuid,'teaching','فحص',null,null,false)::text$q$),
    (4, 'فحص: الفصلُ S1 بمعلّمٍ آخرَ B في وقته', null, $q$select public.v2_slot_check(current_setting('t.school')::uuid,null,current_setting('t.wd')::smallint,current_setting('t.per')::smallint,current_setting('t.sec1')::uuid,current_setting('t.tb')::uuid,'teaching')::text$q$),
    (5, 'حفظُه بلا إقرار', null, $q$select public.v2_slot_save(current_setting('t.school')::uuid,null,current_setting('t.wd')::smallint,current_setting('t.per')::smallint,current_setting('t.sec1')::uuid,current_setting('t.tb')::uuid,'teaching','فحص',null,null,false)::text$q$),
    (6, 'حفظُه بإقرار (p_force)', 'forced', $q$select r->>'slot' from (select public.v2_slot_save(current_setting('t.school')::uuid,null,current_setting('t.wd')::smallint,current_setting('t.per')::smallint,current_setting('t.sec1')::uuid,current_setting('t.tb')::uuid,'teaching','فحص',null,null,true) r) z$q$),
    (7, 'ردُّ الحفظ بإقرار', null, $q$select (select r::text from (select public.v2_slot_save(current_setting('t.school')::uuid,current_setting('t.forced')::uuid,current_setting('t.wd')::smallint,current_setting('t.per')::smallint,current_setting('t.sec1')::uuid,current_setting('t.tb')::uuid,'teaching','فحص ٢',null,null,true) r) z)$q$),
    (8, 'تدريسٌ بلا فصل', null, $q$select public.v2_slot_save(current_setting('t.school')::uuid,null,1::smallint,1::smallint,null,current_setting('t.tb')::uuid,'teaching','فحص',null,null,true)::text$q$),
    (9, 'حصّةٌ خارجَ حصص المدرسة (٩٩)', null, $q$select public.v2_slot_save(current_setting('t.school')::uuid,null,1::smallint,99::smallint,current_setting('t.sec1')::uuid,current_setting('t.tb')::uuid,'teaching','فحص',null,null,true)::text$q$),
    (10, 'معلّمٌ من مدرسةٍ أخرى', null, $q$select public.v2_slot_save(current_setting('t.school')::uuid,null,1::smallint,1::smallint,current_setting('t.sec1')::uuid,current_setting('t.other')::uuid,'teaching','فحص',null,null,true)::text$q$),
    (11, 'انتظارٌ بلا فصل', 'standby', $q$select r->>'slot' from (select public.v2_slot_save(current_setting('t.school')::uuid,null,current_setting('t.wd')::smallint,current_setting('t.per')::smallint,null,current_setting('t.tb')::uuid,'standby',null,null,null,true) r) z$q$),
    (12, 'حذفٌ بلا سبب', null, $q$select public.v2_slot_delete(current_setting('t.forced')::uuid,null)::text$q$),
    (13, 'حذفٌ بسبب', null, $q$select public.v2_slot_delete(current_setting('t.forced')::uuid,'أُضيفت في الفحص')::text$q$),
    (14, 'النصابُ والخطّة (يقرؤهما)', null, $q$select 'quota '||jsonb_array_length(r->'quota')||' · plan '||jsonb_array_length(r->'plan')||' · teachers '||jsonb_array_length(r->'teachers')||' · balance '||(r->'balance')::text||' ‖ '||(r->'plan'->0)::text||' ‖ '||(select (x)::text from jsonb_array_elements(r->'teachers') x where jsonb_array_length(x->'subjects')>0 limit 1) from (select public.v2_quota_board(current_setting('t.school')::uuid) r) z$q$),
    (15, 'يضبط النصاب (وكيلُ شؤون الطلاب)', null, $q$select public.v2_quota_save(current_setting('t.school')::uuid,'subject_teacher',null,10::smallint,null,'فحص')::text$q$),
    (16, 'يقترح جدولًا (وكيلُ شؤون الطلاب)', null, $q$select public.v2_timetable_suggest(current_setting('t.school')::uuid,false,'فحص')::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'وكيلُ الطلاب · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- تجهيز: تكليفٌ مؤقّتٌ «وكيل المدرسة» لمفرح في الطفيل — داخل التراجع
-- (الإصدارُ الأوّل أغفل year_id فرفضه القيدُ وتراجع كلُّه؛ وأُعيد مرّةً بهذا)
insert into v2.assignments(school_id,year_id,post_key,person_id,letter_no,letter_date,started_on,reason)
values (current_setting('t.school')::uuid,(select id from v2.academic_years where school_id=current_setting('t.school')::uuid and is_current),
        'deputy',current_setting('t.mof')::uuid,'فحص-٢٣',current_date,current_date,'تكليفٌ مؤقّتٌ داخل الفحص');

-- ② مفرح بصفة وكيل المدرسة
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (17, 'نصابٌ أدناه فوق أعلاه', null::text, $q$select public.v2_quota_save(current_setting('t.school')::uuid,'subject_teacher',12::smallint,10::smallint,null,null)::text$q$),
    (18, 'نصابُ معلّم المادّة: ١٠', null, $q$select public.v2_quota_save(current_setting('t.school')::uuid,'subject_teacher',null,10::smallint,null,'فحص')::text$q$),
    (19, 'مادّةٌ بلا حصص', null, $q$select public.v2_plan_save(current_setting('t.school')::uuid,null,7::smallint,'فحص',null,null)::text$q$),
    (20, 'تخصّصٌ لمعلّمٍ من مدرسةٍ أخرى', null, $q$select public.v2_teacher_subject(current_setting('t.school')::uuid,current_setting('t.other')::uuid,'الرياضيات',true,false)::text$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'وكيلُ المدرسة · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- تجهيز: خطّةُ الطفيل غيرُ فاعلةٍ لحظةً — داخل التراجع — ليُفحص «اقتراحٌ بلا خطّة»
select set_config('t.plan_n',(select count(*)::text from v2.subject_plan where school_id=current_setting('t.school')::uuid and active),true),
       set_config('t.plan_ids',(select string_agg(id::text,',') from v2.subject_plan where school_id=current_setting('t.school')::uuid and active),true);
update v2.subject_plan set active=false where school_id=current_setting('t.school')::uuid and active;
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
do $$ declare r text; begin
  begin r := 'نفذ: '||public.v2_timetable_suggest(current_setting('t.school')::uuid,false,'بلا خطّة')::text;
  exception when others then r := 'رُفض: '||sqlerrm; end;
  perform set_config('t.s21', 'وكيلُ المدرسة · اقتراحٌ بلا خطّةِ موادّ ⇐ '||r, true);
end $$;
reset role;
update v2.subject_plan set active=true where id = any (string_to_array(current_setting('t.plan_ids'),',')::uuid[]);

-- ③ الاقتراحُ والإقرار
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
do $$ declare s record; r text; begin
  for s in select * from (values
    (22, 'يقترح (لا يثبّت القائم)', 'draft', $q$select r->>'draft' from (select public.v2_timetable_suggest(current_setting('t.school')::uuid,false,'فحص ٢٣') r) z$q$),
    (23, 'نتيجةُ الاقتراح', null, $q$select 'placed '||(d->'stats'->>'placed')||' · unplaced '||(d->'stats'->>'unplaced')||' · standby '||(d->'stats'->>'standby')||' · gaps '||jsonb_array_length(coalesce(d->'stats'->'gaps','[]'))||' ‖ '||coalesce((d->'stats'->'gaps'->0)::text,'—') from (select public.v2_draft_card(current_setting('t.draft')::uuid)->'draft' d) z$q$),
    (24, 'لا يتجاوز نصابًا: أعلى حملِ تدريسٍ لمن نصابُه ١٠', null, $q$select coalesce(max((x->>'teaching')::int),0)::text||' (والنصاب ١٠ لمعلّمي المادّة)' from jsonb_array_elements(public.v2_draft_card(current_setting('t.draft')::uuid)->'load') x$q$),
    (25, 'كلُّ خانةٍ بسببها', null, $q$select count(*) filter (where coalesce(x->>'why','')='')||' بلا سبب من '||count(*)||' · '||(select string_agg(distinct x2->>'why',' | ') from jsonb_array_elements(public.v2_draft_card(current_setting('t.draft')::uuid)->'slots') x2) from jsonb_array_elements(public.v2_draft_card(current_setting('t.draft')::uuid)->'slots') x$q$),
    (26, 'الجدولُ القائمُ لم يُمسّ قبل الإقرار', null, $q$select jsonb_array_length(public.v2_timetable_board(current_setting('t.school')::uuid,null,null,null)->'slots')::text$q$),
    (27, 'يُقرّ بغير «أقرّ»', null, $q$select public.v2_draft_apply(current_setting('t.draft')::uuid,'نعم')::text$q$),
    (28, 'يُقرّ بـ«أقرّ»', null, $q$select public.v2_draft_apply(current_setting('t.draft')::uuid,'أقرّ')::text$q$),
    (29, 'يُقرّ ثانيةً', null, $q$select public.v2_draft_apply(current_setting('t.draft')::uuid,'أقرّ')::text$q$),
    (30, 'الجدولُ بعد الإقرار', null, $q$select jsonb_array_length(public.v2_timetable_board(current_setting('t.school')::uuid,null,null,null)->'slots')::text$q$),
    (31, 'قائمةُ المقترحات', null, $q$select jsonb_array_length(r)||' · '||(r->0->>'state')||' · made_by='||coalesce(r->0->>'made_by','—')||' · applied_at='||coalesce(r->0->>'applied_at','—')||' · '||(select string_agg(k,',' order by k) from jsonb_object_keys(r->0) k) from (select public.v2_drafts_list(current_setting('t.school')::uuid) r) z$q$),
    (32, 'إلغاءُ مقترحٍ مُقَرّ', null, $q$select public.v2_draft_cancel(current_setting('t.draft')::uuid,'فحص')::text$q$),
    (33, 'مقترحٌ ثانٍ ثمّ إلغاؤه بلا سبب', 'draft2', $q$select r->>'draft' from (select public.v2_timetable_suggest(current_setting('t.school')::uuid,false,'فحص ٢٣ ب') r) z$q$),
    (34, 'إلغاءٌ بلا سبب', null, $q$select public.v2_draft_cancel(current_setting('t.draft2')::uuid,'')::text$q$),
    (35, 'المقترحُ المُقَرّ: applied_by', null, $q$select coalesce(public.v2_draft_card(current_setting('t.draft')::uuid)->'draft'->>'applied_by','—')$q$),
    (36, 'خانةٌ من يوم ١ في اللوح: weekday و weekday_ar', null, $q$select (select x::text from jsonb_array_elements(public.v2_timetable_board(current_setting('t.school')::uuid,null,null,1::smallint)->'slots') x limit 1)$q$),
    (37, 'v2_sections', null, $q$select jsonb_array_length(r)||' فصلًا ‖ '||(r->0)::text from (select public.v2_sections(current_setting('t.school')::uuid) r) z$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'وكيلُ المدرسة · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", left(current_setting('t.s'||n),1200) as النتيجة from generate_series(1,37) n
union all select 'أ', 'الحصّة x: يوم '||current_setting('t.wd')||' حصّة '||current_setting('t.per')||' · A '||current_setting('t.ta')||' · S1 '||current_setting('t.sec1')||' · S2 '||coalesce(current_setting('t.sec2'),'—')||' · B '||coalesce(current_setting('t.tb'),'—')||' · من مالك '||coalesce(current_setting('t.other'),'—')||' · سطورُ الخطّة '||current_setting('t.plan_n');
rollback;
