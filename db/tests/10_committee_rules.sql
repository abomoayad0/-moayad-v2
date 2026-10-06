-- فحص ١٠ (الإصدار ٢) · قواعدُ اللجنة بعد p_quorum_mode، ومجلسُ اللجنة بـ quorum_ar و duties.
-- الإصدارُ الأوّل كان يمرّر p_clear_quorum (boolean) معاملًا سابعًا، وقد صار p_quorum_mode (text). كلُّه داخل begin … rollback.
begin;
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);

-- الموجّه
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'يقرأ القواعد', null::text, $q$select 'mode='||(r->>'quorum_mode')||' · min='||coalesce(r->>'quorum_min','null')||' · '||(r->>'quorum_ar')||' · remote='||(r->>'allow_remote')||' · tie='||(r->>'tie_rule')||' · seated='||(r->>'seated') from (select public.v2_committee_rules_get('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance') r) z$q$),
    (2, 'يضبط القواعد', null::text, $q$select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance',3::smallint,null,null,'فحص','fixed')::text$q$)
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
    (3, 'يقرأ قواعدَ مدرسةٍ أخرى', null::text, $q$select public.v2_committee_rules_get('f789f9ea-e474-49bc-86e0-3449258815f8','guidance')::text$q$),
    (4, 'ثابت 3 · عن بُعد لا · تأجيل', null::text, $q$select 'mode='||(r->>'quorum_mode')||' · min='||coalesce(r->>'quorum_min','null')||' · '||(r->>'quorum_ar')||' · remote='||(r->>'allow_remote')||' · tie='||(r->>'tie_rule') from (select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance',3::smallint,false,'تأجيل','فحص','fixed') r) z$q$),
    (5, 'المجلسُ بعدها', null::text, $q$select 'quorum='||coalesce(c->>'quorum','null')||' · '||(c->>'quorum_ar')||' · mode='||(c->>'quorum_mode')||' · remote='||(c->>'allow_remote')||' · tie='||(c->>'tie_rule')||' · seated='||(c->>'seated') from (select public.v2_committee_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance')->'committee' c) z$q$),
    (6, 'ثابت 4 وحده (والباقي لا يتغيّر)', null::text, $q$select 'mode='||(r->>'quorum_mode')||' · min='||coalesce(r->>'quorum_min','null')||' · '||(r->>'quorum_ar')||' · remote='||(r->>'allow_remote')||' · tie='||(r->>'tie_rule') from (select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance',4::smallint,null,null,'فحص','fixed') r) z$q$),
    (7, 'ثابت 1', null::text, $q$select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance',1::smallint,null,null,'فحص','fixed')::text$q$),
    (8, 'ثابت فوق الأعضاء', null::text, $q$select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance',99::smallint,null,null,'فحص','fixed')::text$q$),
    (9, 'ثابتٌ بلا عدد', null::text, $q$select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance',null,null,null,'فحص','fixed')::text$q$),
    (10, 'وضعٌ مجهول', null::text, $q$select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance',null,null,null,'فحص','half')::text$q$),
    (11, 'حكمُ تعادلٍ غيرُ معروف', null::text, $q$select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance',null,null,'قرعة','فحص',null)::text$q$),
    (12, 'بلا نصاب', null::text, $q$select 'mode='||(r->>'quorum_mode')||' · min='||coalesce(r->>'quorum_min','null')||' · '||(r->>'quorum_ar')||' · remote='||(r->>'allow_remote')||' · tie='||(r->>'tie_rule') from (select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance',null,null,null,'فحص','none') r) z$q$),
    (13, 'المجلسُ بعده', null::text, $q$select 'quorum='||coalesce(c->>'quorum','null')||' · '||(c->>'quorum_ar') from (select public.v2_committee_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance')->'committee' c) z$q$),
    (14, 'فوق النصف', null::text, $q$select 'mode='||(r->>'quorum_mode')||' · min='||coalesce(r->>'quorum_min','null')||' · '||(r->>'quorum_ar')||' · remote='||(r->>'allow_remote')||' · tie='||(r->>'tie_rule') from (select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance',null,null,null,'فحص','majority') r) z$q$),
    (15, 'بلا وضعٍ (null) بعد فوق النصف', null::text, $q$select 'mode='||(r->>'quorum_mode')||' · min='||coalesce(r->>'quorum_min','null')||' · '||(r->>'quorum_ar')||' · remote='||(r->>'allow_remote')||' · tie='||(r->>'tie_rule') from (select public.v2_committee_rules('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance',3::smallint,null,null,'فحص',null) r) z$q$),
    (16, 'سعةُ الدليل مقابل المدرسة حين تختلفان', null::text, $q$select coalesce((select string_agg(coalesce(e->>'role_ar','')||' '||(e->>'count')||'/'||(e->>'count_guide'),' · ') from jsonb_array_elements(public.v2_committee_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance')->'seats') e where (e->>'count') is distinct from (e->>'count_guide')),'لا اختلاف')$q$),
    (17, 'مهامُّ اللجنة في المجلس', null::text, $q$select jsonb_array_length(d)||' · منها للمدرسة '||(select count(*) from jsonb_array_elements(d) x where (x->>'mine')::boolean)||' · بلا سند '||(select count(*) from jsonb_array_elements(d) x where coalesce(x->>'source','')='')||' · الدوريّات: '||(select string_agg(distinct coalesce(x->>'cadence','—'),' · ') from jsonb_array_elements(d) x) from (select public.v2_committee_board('7a847bb1-9b14-41ad-b9ba-7c8dee61a992'::uuid,'guidance')->'duties' d) z$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, r, true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, 'الوكيل · '||s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;

select n::text as "#", current_setting('t.s'||n) as النتيجة from generate_series(1,17) n;
rollback;
