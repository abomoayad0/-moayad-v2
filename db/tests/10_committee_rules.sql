-- فحص ١٠ · قواعدُ اللجان: القراءةُ (v2_committee_rules_get)، والضبطُ في نداءٍ واحد، وإلغاءُ النصاب صراحةً،
-- ومطابقةُ المجلس (v2_committee_board) للقواعد، وسعةُ الدليل مقابل سعةِ المدرسة. كلُّه داخل begin … rollback.
begin;
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);

-- الموجّه
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'يقرأ القواعد', null::text, $q$select public.v2_committee_rules_get('7a847bb1-9b14-41ad-b9ba-7c8dee61a992','guidance')::text$q$),
    (2, 'يضبط القواعد', null::text, $q$select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992','guidance',3::smallint,null,null,'فحص',false)::text$q$)
  ) v(n,l,k,q) order by n loop
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
do $$ declare s record; r text; begin
  for s in select * from (values
    (3, 'يقرأ القواعد', null::text, $q$select public.v2_committee_rules_get('7a847bb1-9b14-41ad-b9ba-7c8dee61a992','guidance')::text$q$),
    (4, 'يقرأ قواعدَ مدرسةٍ أخرى', null::text, $q$select public.v2_committee_rules_get('f789f9ea-e474-49bc-86e0-3449258815f8','guidance')::text$q$),
    (5, 'يضبط: نصاب 3 · عن بُعد لا · تأجيل', null::text, $q$select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992','guidance',3::smallint,false,'تأجيل','فحص',false)::text$q$),
    (6, 'المجلسُ بعدها', null::text, $q$select 'quorum='||coalesce((public.v2_committee_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992','guidance')->'committee')->>'quorum','null')||' · allow_remote='||((public.v2_committee_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992','guidance')->'committee')->>'allow_remote')||' · tie='||((public.v2_committee_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992','guidance')->'committee')->>'tie_rule')$q$),
    (7, 'يضبط النصابَ وحده 4 (والباقي لا يتغيّر)', null::text, $q$select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992','guidance',4::smallint,null,null,'فحص',false)::text$q$),
    (8, 'نصابٌ دون اثنين', null::text, $q$select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992','guidance',1::smallint,null,null,'فحص',false)::text$q$),
    (9, 'نصابٌ فوق المقاعد', null::text, $q$select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992','guidance',99::smallint,null,null,'فحص',false)::text$q$),
    (10, 'حكمُ تعادلٍ غيرُ معروف', null::text, $q$select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992','guidance',null,null,'قرعة','فحص',false)::text$q$),
    (11, 'يُلغي النصابَ صراحةً', null::text, $q$select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992','guidance',null,null,null,'فحص',true)::text$q$),
    (12, 'القراءةُ بعد الإلغاء', null::text, $q$select public.v2_committee_rules_get('7a847bb1-9b14-41ad-b9ba-7c8dee61a992','guidance')::text$q$),
    (13, 'المجلسُ بعد الإلغاء', null::text, $q$select 'quorum='||coalesce((public.v2_committee_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992','guidance')->'committee')->>'quorum','null')$q$),
    (14, 'سعةُ الدليل مقابل سعةِ المدرسة حين تختلفان', null::text, $q$select coalesce((select string_agg(coalesce(e->>'role_ar','')||' '||(e->>'count')||'/'||(e->>'count_guide'),' · ') from jsonb_array_elements(public.v2_committee_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992','guidance')->'seats') e where (e->>'count') is distinct from (e->>'count_guide')),'لا اختلاف')$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الوكيل · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", current_setting('t.s'||n) as النتيجة from generate_series(1,14) n;

rollback;
