-- فحص ١٨ · شاشةُ رائد النشاط (viewA) على القاعدة — الإقرارُ والإحالةُ بأشكال ما ترسله raed.js، ثمّ التقديرُ بعده.
-- لا هويّةَ لرائد نشاطٍ في القاعدة، فيقيم الفرصةَ سعيدٌ (operator) كما يقيمها رائدُ النشاط، ومفرح (owner).
-- تجهيز: رفعُ النموذج يلزمه ملفٌّ في المخزن (يحرسه g_verdict_needs_filing)، فيُكتب صفُّه في storage.objects داخل التراجع ثمّ يُعلَّم «مرفوعًا» — لا رفعَ ولا حذف. كلُّه داخل begin … rollback.
-- (الإصدارُ الأوّلُ علّم المشاركةَ مرفوعةً بلا صفٍّ في المخزن فرفضه الحارس وتراجع كلُّه؛ وأُعيد مرّةً بهذا التجهيز.)
begin;
set local lock_timeout = '5s';
set local statement_timeout = '20s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.saeed',(select person_id::text from v2.app_users where id='52bc11f6-8e82-44cd-9f4d-e9bf43aee128'),true),
       set_config('t.mof',(select person_id::text from v2.app_users where id='11be0946-ff39-4eb7-8a74-023b580479be'),true),
       set_config('t.merit',(select id::text from v2.conduct_merits where points is not null and id<>1 order by id limit 1),true),
       set_config('t.pts',(select points::text from v2.conduct_merits where points is not null and id<>1 order by id limit 1),true);
select set_config('t.a',(select e.student_id::text from v2.enrolments e where e.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid and e.status='active'
          order by e.student_id limit 1),true);

-- تجهيز: مفرح يفتح فرصةً يقيمها سعيد، ويسجّل الطالبَ، ويغلقها
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
select set_config('t.opp', public.v2_opp_open(current_setting('t.school')::uuid,current_setting('t.merit')::int,'منظَّمة','فحص ١٨','الإذاعة · الأحد',null,current_setting('t.saeed')::uuid)->>'opp', true);
select set_config('t.entry', split_part(public.v2_opp_join(current_setting('t.opp')::uuid,current_setting('t.a')::uuid)->>'upload_to','/',4), true);
select public.v2_opp_close(current_setting('t.opp')::uuid,'انتهى الوقت');
reset role;
insert into storage.objects(bucket_id,name) values ('v2-attachments', v2.evidence_path_for(current_setting('t.entry')::uuid)||'fixture.png');
update v2.merit_entries set filed_at=now(), what_ar='قدّمتُ فقرة الحديث', evidence_desc='صورة', evidence_name=v2.evidence_path_for(id)||'fixture.png'
 where id=current_setting('t.entry')::uuid;

-- ① سعيد — مقيمُ الفرصة (operator)
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'v2_me: can.merit (يفتح الشاشة)', $q$select coalesce(r->>'role_ar','—')||' · raed='||coalesce(r->'can'->>'raed','—')||' · merit='||coalesce(r->'can'->>'merit','—') from (select public.v2_me() r) z$q$),
    (2, 'ما ينتظر إقرارَه', $q$select jsonb_array_length(r)||' · '||coalesce((select (x->>'mine')||'/'||coalesce(x->>'delegated_to_me','null')||' · '||(select string_agg(k,',' order by k) from jsonb_object_keys(x) k) from jsonb_array_elements(r) x where x->>'entry'=current_setting('t.entry')),'المشاركةُ ليست فيه') from (select public.v2_entries_pending(current_setting('t.school')::uuid) r) z$q$),
    (3, 'يقرّ: نفّذ بملاحظة', $q$select public.v2_entry_verdict(current_setting('t.entry')::uuid,'نفّذ','قدّم فقرته',null)::text$q$),
    (4, 'يحيل الإقرارَ إلى مفرح', $q$select public.v2_entry_delegate(current_setting('t.entry')::uuid,current_setting('t.mof')::uuid,'لم أحضر')::text$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'سعيد · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- ② مفرح — owner
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (5, 'ما ينتظر (owner يرى الكلّ)', $q$select jsonb_array_length(r)||' · '||coalesce((select (x->>'student')||' — '||(x->>'merit')||' · what='||(x->>'what')||' · evidence='||(x->>'evidence') from jsonb_array_elements(r) x where x->>'entry'=current_setting('t.entry')),'ليست فيه') from (select public.v2_entries_pending(current_setting('t.school')::uuid) r) z$q$),
    (6, 'يقرّ بلا ملاحظة (null كما ترسله الشاشة)', $q$select public.v2_entry_verdict(current_setting('t.entry')::uuid,'نفّذ',null,null)::text$q$),
    (7, 'يقرّ بحكمٍ خارج الأربعة', $q$select public.v2_entry_verdict(current_setting('t.entry')::uuid,'ممتاز','ملاحظة',null)::text$q$),
    (8, 'يحيل بلا سبب', $q$select public.v2_entry_delegate(current_setting('t.entry')::uuid,current_setting('t.saeed')::uuid,null)::text$q$),
    (9, 'يحيل إلى سعيد بسبب', $q$select public.v2_entry_delegate(current_setting('t.entry')::uuid,current_setting('t.saeed')::uuid,'حضر الإذاعة')::text$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'مفرح · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- ③ سعيد — المحالُ إليه
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (10, 'ما ينتظره بعد الإحالة', $q$select coalesce((select (x->>'mine')||'/'||coalesce(x->>'delegated_to_me','null')||' · '||coalesce(x->>'delegate_note','—') from jsonb_array_elements(public.v2_entries_pending(current_setting('t.school')::uuid)) x where x->>'entry'=current_setting('t.entry')),'ليست فيه')$q$),
    (11, 'يقرّ وهو المحالُ إليه', $q$select public.v2_entry_verdict(current_setting('t.entry')::uuid,'نفّذ','قدّم فقرته',null)::text$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'سعيد · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- ④ مفرح — يقرّ ثمّ يقدّر
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (12, 'يقرّ: نفّذ جزئيًّا', $q$select public.v2_entry_verdict(current_setting('t.entry')::uuid,'نفّذ جزئيًّا','قدّم نصفها',null)::text$q$),
    (13, 'يقرّ ثانيةً: لم يحضر', $q$select public.v2_entry_verdict(current_setting('t.entry')::uuid,'لم يحضر','تبديل',null)::text$q$),
    (14, 'ما ينتظر بعد الإقرار', $q$select coalesce((select 'باقية' from jsonb_array_elements(public.v2_entries_pending(current_setting('t.school')::uuid)) x where x->>'entry'=current_setting('t.entry')),'خرجت')$q$),
    (15, 'اللجنةُ تقدّر', $q$select public.v2_entry_grade(current_setting('t.entry')::uuid,current_setting('t.pts')::numeric,'توصية')::text$q$),
    (16, 'البنك: العدّادات', $q$select 'filed='||(x->>'filed')||' · verdicted='||(x->>'verdicted')||' · graded='||(x->>'graded') from jsonb_array_elements(public.v2_opps_list(current_setting('t.school')::uuid,null,180)) x where x->>'opp'=current_setting('t.opp')$q$),
    (17, 'ملفُّ الفرصة: العضو', $q$select (public.v2_opp_card(current_setting('t.opp')::uuid)->'members'->0)::text$q$),
    (18, 'يقرّ ثالثةً قبل التقدير: نفّذ', $q$select public.v2_entry_verdict(current_setting('t.entry')::uuid,'نفّذ','قدّم الفقرة كاملة',null)::text$q$),
    (19, 'اللجنةُ تقدّر', $q$select public.v2_entry_grade(current_setting('t.entry')::uuid,current_setting('t.pts')::numeric,'توصية')::text$q$),
    (20, 'إقرارٌ بعد التقدير', $q$select public.v2_entry_verdict(current_setting('t.entry')::uuid,'لم ينفّذ','بعد التقدير',null)::text$q$),
    (21, 'اعتمادُ المخطّط', $q$select public.v2_opp_plan(current_setting('t.opp')::uuid,'اعتُمد')::text$q$),
    (22, 'العضوُ بعدها: الحكمُ وسابقُه', $q$select (r->>'verdict')||' · graded='||(r->>'graded')||' · points='||coalesce(r->>'points','—')||' · '||(select string_agg(k,',' order by k) from jsonb_object_keys(r) k) from (select public.v2_opp_card(current_setting('t.opp')::uuid)->'members'->0 r) z$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'مفرح · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", left(current_setting('t.s'||n),1400) as النتيجة from generate_series(1,22) n
union all select 'أ', 'الممارسة '||current_setting('t.merit')||' بدرجة '||current_setting('t.pts')||' · الفرصة '||coalesce(current_setting('t.opp'),'—')||' · المشاركة '||coalesce(current_setting('t.entry'),'—');
rollback;
