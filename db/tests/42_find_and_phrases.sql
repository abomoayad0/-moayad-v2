-- فحص ٤٢ · تكليفُ الشاشات ⑤: البحثُ في المدرسة كلِّها (v2_students_board بالوسيط الخامس) · توأمُه · آخرُ من عملتَ عليهم · منبعُ حقول النموذج · المكتبة
-- كلُّه داخل begin…rollback — بحساب مفرح (مالك) لشكل الجواب، وبحساب معلّمٍ لحارس الصفة
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
select set_config('t.stu','04335119-5a39-45ad-ac13-4c1988c3034a',true);
do $$ begin
  perform set_config('t.rec',(select br.id::text from v2.behavior_records br where br.student_id::text=current_setting('t.stu') and br.status<>'voided' order by br.created_at desc limit 1),true);
end $$;
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'البحثُ بالوسائط الأربعة (التوأم)', $q$select public.v2_students_board(p_school=>current_setting('t.school')::uuid, p_grade=>null::smallint, p_section=>null::text, p_q=>'حس')::text$q$),
    (2, 'البحثُ بالخامس «حس»', $q$select 'count '||(r->>'count')||' · total '||(r->>'total')||' · more '||(r->>'more')||' · '||(r->>'summary_ar')||' · أوّلُهم '||coalesce(r->'rows'->0->>'display','∅') from (select public.v2_students_board(p_school=>current_setting('t.school')::uuid, p_grade=>null::smallint, p_section=>null::text, p_q=>'حس', p_limit=>30) r) z$q$),
    (3, 'بلا بحثٍ وبحدٍّ ٥', $q$select 'count '||(r->>'count')||' · total '||(r->>'total')||' · more '||(r->>'more')||' · '||(r->>'summary_ar') from (select public.v2_students_board(p_school=>current_setting('t.school')::uuid, p_grade=>null::smallint, p_section=>null::text, p_q=>null::text, p_limit=>5) r) z$q$),
    (4, 'آخرُ من عملتُ عليهم', $q$select (r->>'summary_ar')||' · '||coalesce(r->'rows'->0->>'name','∅')||' · '||coalesce(r->'rows'->0->>'last_ar','∅')||' ‖ '||(r->>'note_ar') from (select public.v2_recent_students(5) r) z$q$),
    (5, 'v2_form_open (٣) — منبعُ حقوله', $q$select (select string_agg((x->>'key')||':'||coalesce(x->>'source','∅')||'/'||coalesce(x->>'phrases_n','∅'),' · ') from jsonb_array_elements(r->'schema') x) from (select public.v2_form_open(3::smallint,current_setting('t.stu')::uuid,nullif(current_setting('t.rec'),'')::uuid,null) r) z$q$),
    (6, 'v2_phrases_for (٣ · problem_desc)', $q$select (r->>'source_ar')||' · محسوب '||jsonb_array_length(r->'computed')||' «'||left(coalesce(r->'computed'->0->>'text','∅'),40)||'» لأنّ '||coalesce(r->'computed'->0->>'why','∅')||' · عبارات '||jsonb_array_length(r->'phrases')||' · أوّلُها طبقة '||coalesce(r->'phrases'->0->>'layer','∅')||' «'||left(coalesce(r->'phrases'->0->>'text','∅'),40)||'» '||coalesce(r->'phrases'->0->>'why','∅')||' ‖ '||coalesce(r->>'summary_ar','∅')||' ‖ how '||coalesce(r->>'how_ar','∅') from (select public.v2_phrases_for(3::smallint,'problem_desc',nullif(current_setting('t.rec'),'')::uuid,null) r) z$q$),
    (7, 'v2_phrase_use لأوّلها', $q$select (public.v2_phrase_use(((public.v2_phrases_for(3::smallint,'problem_desc',nullif(current_setting('t.rec'),'')::uuid,null))->'phrases'->0->>'id')::uuid, 3::smallint, 'problem_desc'))::text$q$),
    (8, 'v2_phrase_add قصيرة', $q$select public.v2_phrase_add(3::smallint,'problem_desc','قصير')::text$q$),
    (9, 'v2_phrase_add تامّة', $q$select (public.v2_phrase_add(3::smallint,'problem_desc','ينام الطالبُ في الحصّة الأولى غالبًا لتأخّر نومه ليلًا'))->>'note_ar'$q$),
    (10, 'v2_phrase_add لحقلٍ بيدك', $q$select public.v2_phrase_add(3::smallint,(select s.key from v2.form_schema s join v2.form_field_source fs on fs.form_no=s.form_no and fs.field_key=s.key where fs.by_hand limit 1),'نصٌّ طويلٌ كفايةً ليُحفظ في المكتبة')::text$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||left(coalesce(r,'—'),600); exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
set local request.jwt.claims = '{"sub":"5e17dd28-15ef-4c80-b7ba-0cb3d9e4141d","role":"authenticated"}';
select public.v2_act_as('subject_teacher', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (11, 'المعلّم · البحث', $q$select (public.v2_students_board(p_school=>current_setting('t.school')::uuid, p_grade=>null::smallint, p_section=>null::text, p_q=>'حس', p_limit=>30))->>'summary_ar'$q$),
    (12, 'المعلّم · آخرُ من عمل عليهم', $q$select (public.v2_recent_students(5))->>'summary_ar'$q$),
    (13, 'المعلّم · عباراتُ الحقل', $q$select (public.v2_phrases_for(3::smallint,'problem_desc',null,null))->>'summary_ar'$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—'); exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
select n, current_setting('t.s'||n, true) as result from generate_series(1,13) n;
rollback;
