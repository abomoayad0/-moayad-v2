-- فحص ١٧ · شاشةُ اللجنة (viewC) على القاعدة — بالنداءات التي ترسلها lajna.js وبأشكال معاملاتها.
-- الاجتماعُ والنصابُ والتصويتُ فُحصت في ١٣أ؛ وهنا: ما تقرؤه الشاشةُ منها، ومسارُ الفرصة كاملًا: فتحٌ ⇒ تسجيلٌ ⇒ إغلاقٌ ⇒ إقرارٌ ⇒ تقديرٌ ⇒ مخطّط.
-- كلُّه داخل begin … rollback. الهويّات: مفرح (وكيل · رئيسُ لجنة التوجيه · owner) · سعيد (الموجّه · مقرّرُها) — ويقيم سعيدٌ الفرصةَ هنا.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '20s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.saeed',(select person_id::text from v2.app_users where id='52bc11f6-8e82-44cd-9f4d-e9bf43aee128'),true),
       set_config('t.saeed_grant',(select role from v2.app_users where id='52bc11f6-8e82-44cd-9f4d-e9bf43aee128'),true),
       set_config('t.merit',(select id::text from v2.conduct_merits where points is not null order by id limit 1),true),
       set_config('t.pts',(select points::text from v2.conduct_merits where points is not null order by id limit 1),true);
select set_config('t.a',(select e.student_id::text from v2.enrolments e where e.school_id='7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid and e.status='active'
          order by e.student_id limit 1),true);

-- ① مفرح بصفة الوكيل
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'v2_me: can', null::text, $q$select coalesce(r->>'role_ar','—')||' · lajna='||coalesce(r->'can'->>'lajna','—')||' · merit='||coalesce(r->'can'->>'merit','—') from (select public.v2_me() r) z$q$),
    (2, 'قائمةُ اللجان', null, $q$select jsonb_array_length(r)||' · '||(select string_agg(x->>'key'||'='||(x->>'label'),' · ') from jsonb_array_elements(r) x) from (select public.v2_committees_list(current_setting('t.school')::uuid) r) z$q$),
    (3, 'مجلسُ التوجيه: مقعدي والنصاب', null, $q$select coalesce(r->>'my_seat','—')||' · quorum_ar='||coalesce(r->'committee'->>'quorum_ar','—')||' · المقاعد '||jsonb_array_length(r->'seats')||' · '||(select string_agg(k,',' order by k) from jsonb_object_keys(r->'committee') k) from (select public.v2_committee_board(current_setting('t.school')::uuid,'guidance') r) z$q$),
    (4, 'مهامُّ التوجيه', null, $q$select jsonb_array_length(r)||' · '||(select string_agg(k,',' order by k) from jsonb_object_keys(r->0) k)||' ‖ '||(r->0)::text from (select public.v2_committee_duties(current_setting('t.school')::uuid,'guidance') r) z$q$),
    (5, 'الاجتماعات', null, $q$select jsonb_array_length(r)||coalesce(' · '||(select string_agg(k,',' order by k) from jsonb_object_keys(r->0) k),'') from (select public.v2_meetings_list(current_setting('t.school')::uuid,'guidance',null,180) r) z$q$),
    (6, 'ما عليّ من اللجان', null, $q$select jsonb_array_length(r)::text from (select public.v2_my_committee_tasks(current_setting('t.school')::uuid) r) z$q$),
    (7, 'الممارسات', null, $q$select jsonb_array_length(r)||' · '||(select string_agg(k,',' order by k) from jsonb_object_keys(r->0) k) from (select public.v2_merits() r) z$q$),
    (8, 'افتح فرصةً بلا موعد', null, $q$select public.v2_opp_open(current_setting('t.school')::uuid,current_setting('t.merit')::int,'منظَّمة',null,null,null,current_setting('t.saeed')::uuid)::text$q$),
    (9, 'افتح فرصةً يقيمها سعيد', 'opp', $q$select r->>'opp' from (select public.v2_opp_open(current_setting('t.school')::uuid,current_setting('t.merit')::int,'منظَّمة','فحص ١٧','الإذاعة · الأحد',null,current_setting('t.saeed')::uuid) r) z$q$),
    (10, 'سجّل الطالب نيابةً', 'entry', $q$select split_part(r->>'upload_to','/',4) from (select public.v2_opp_join(current_setting('t.opp')::uuid,current_setting('t.a')::uuid) r) z$q$),
    (11, 'بنكُ الفرص: الفرصة', null, $q$select (select string_agg(k,',' order by k) from jsonb_object_keys(x) k)||' ‖ '||x::text from jsonb_array_elements(public.v2_opps_list(current_setting('t.school')::uuid,null,180)) x where x->>'opp'=current_setting('t.opp')$q$),
    (12, 'تقديرٌ قبل الإقرار', null, $q$select public.v2_entry_grade(current_setting('t.entry')::uuid,1,null)::text$q$),
    (13, 'إغلاقٌ بلا سبب', null, $q$select public.v2_opp_close(current_setting('t.opp')::uuid,null)::text$q$),
    (14, 'إغلاقٌ بسبب', null, $q$select public.v2_opp_close(current_setting('t.opp')::uuid,'انتهى الوقت')::text$q$),
    (15, 'ملفُّ الفرصة: المفاتيح', null, $q$select (select string_agg(k,',' order by k) from jsonb_object_keys(r) k)||' ‖ opp: '||(select string_agg(k,',' order by k) from jsonb_object_keys(r->'opp') k)||' ‖ عضو: '||(select string_agg(k,',' order by k) from jsonb_object_keys(r->'members'->0) k)||' ‖ held_by='||coalesce(r->>'held_by','—') from (select public.v2_opp_card(current_setting('t.opp')::uuid) r) z$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'مفرح · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- ② سعيد بصفة الموجّه — يقيم الفرصة فيقرّ المشاركة
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (16, 'v2_me: can', $q$select coalesce(r->>'role_ar','—')||' · lajna='||coalesce(r->'can'->>'lajna','—')||' · merit='||coalesce(r->'can'->>'merit','—') from (select public.v2_me() r) z$q$),
    (17, 'يقرّ المشاركةَ وهو مقيمُ الفرصة', $q$select public.v2_entry_verdict(current_setting('t.entry')::uuid,'نفّذ','قدّم فقرته',null)::text$q$),
    (18, 'يفتح فرصة (وليس رئيسًا)', $q$select public.v2_opp_open(current_setting('t.school')::uuid,current_setting('t.merit')::int,'منظَّمة',null,'الأحد',null,null)::text$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'سعيد · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

-- ③ مفرح — يقرّ إن لم يقرّ سعيد، ثمّ يقدّر ويعتمد
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (19, 'يقرّ المشاركة إن بقيت بلا إقرار (owner)', $q$select case when public.v2_opp_card(current_setting('t.opp')::uuid)->'members'->0->>'verdict' is null then public.v2_entry_verdict(current_setting('t.entry')::uuid,'نفّذ','قدّم فقرته',null)::text else 'أُقرّت سلفًا من سعيد' end$q$),
    (20, 'اعتمادُ المخطّط قبل التقدير', $q$select public.v2_opp_plan(current_setting('t.opp')::uuid,'توصية')::text$q$),
    (21, 'التقدير بالدرجة ونصٍّ', $q$select public.v2_entry_grade(current_setting('t.entry')::uuid,current_setting('t.pts')::numeric,'توصية اللجنة')::text$q$),
    (22, 'التقديرُ ثانيةً', $q$select public.v2_entry_grade(current_setting('t.entry')::uuid,1,'ثانية')::text$q$),
    (23, 'اعتمادُ المخطّط', $q$select public.v2_opp_plan(current_setting('t.opp')::uuid,'اعتُمد')::text$q$),
    (24, 'البنك بعد الاعتماد', $q$select (x->>'state')||' · verdicted='||(x->>'verdicted')||' · graded='||(x->>'graded')||' · plan_note='||coalesce(x->>'plan_note','—') from jsonb_array_elements(public.v2_opps_list(current_setting('t.school')::uuid,null,180)) x where x->>'opp'=current_setting('t.opp')$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'مفرح · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", left(current_setting('t.s'||n),1400) as النتيجة from generate_series(1,24) n
union all select 'أ', 'صلاحيّةُ سعيد في app_users: '||coalesce(current_setting('t.saeed_grant'),'—')||' · الممارسة '||current_setting('t.merit')||' بدرجة '||current_setting('t.pts');
rollback;
