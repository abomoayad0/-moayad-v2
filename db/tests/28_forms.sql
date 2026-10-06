-- فحص ٢٨ · النموذجُ الرسميّ — فتحٌ وحفظُ مسوّدةٍ واعتمادٌ وتوقيعٌ وامتناعٌ وإلغاء، بالنداءات التي ترسلها form.js.
-- كلُّه داخل begin … rollback. الهويّة: مفرح وكيلًا لشؤون الطلاب في الطفيل. والنموذج ٥ (رصد مشكلة سلوكية) لطالبٍ له رصدة.
-- الإصدار ٢: في الأوّل قرأتُ المعرّفَ من مفتاح entry، والجسرُ يرجعه في entry_id — فتعطّلت السطور ٣–٩.
-- الحقولُ اللازمة تُملأ من schema نفسِه بحسب input: date ⇐ اليوم · number ⇐ ١ · checkbox ⇐ true · select ⇐ أوّلُ خياراته · وإلا ⇐ «فحص».
begin;
set local lock_timeout = '5s';
set local statement_timeout = '30s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true),
       set_config('t.stu','5f5e70d0-e519-4e26-b254-64885d0fbb6a',true),
       set_config('t.form','5',true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; d jsonb; begin
  d := public.v2_form_open(current_setting('t.form')::smallint, current_setting('t.stu')::uuid, null, null);
  perform set_config('t.signer', coalesce(d->'signers'->>0,''), true);
  perform set_config('t.data', coalesce((select jsonb_object_agg(f->>'key', case f->>'input'
        when 'date' then to_jsonb(current_date::text) when 'number' then to_jsonb(1) when 'checkbox' then to_jsonb(true)
        when 'select' then coalesce(f->'options'->0, to_jsonb('فحص'::text)) else to_jsonb('فحص'::text) end)
      from jsonb_array_elements(d->'schema') f where coalesce(f->>'input','') not in ('auto','derived')),'{}'::jsonb)::text, true);
  for s in select * from (values
    (1, 'فتحُ النموذج ٥', null::text, $q$select 'form '||(r->>'form_no')||' · '||(r->>'title_ar')||' · خانات '||jsonb_array_length(coalesce(r->'schema','[]'))||' · أعمدة '||jsonb_array_length(coalesce(r->'row_schema','[]'))||' · موقّعون '||coalesce((r->'signers')::text,'∅')||' · can_edit='||coalesce(r->>'can_edit','∅')||' · entry='||coalesce(r->'entry'->>'status','∅')||' · final_label='||coalesce(r->>'final_label_ar','∅') from (select public.v2_form_open(current_setting('t.form')::smallint,current_setting('t.stu')::uuid,null,null) r) z$q$),
    (2, 'حفظُ مسوّدةٍ فارغة', 'entry', $q$select r->>'entry_id' from (select public.v2_form_save(current_setting('t.form')::smallint,'{}'::jsonb,'[]'::jsonb,current_setting('t.stu')::uuid,null,null,null,false) r) z$q$),
    (3, 'اعتمادُها فارغةً', null, $q$select public.v2_form_save(current_setting('t.form')::smallint,'{}'::jsonb,'[]'::jsonb,current_setting('t.stu')::uuid,null,null,nullif(current_setting('t.entry'),'')::uuid,true)::text$q$),
    (4, 'اعتمادُها بحقولها', null, $q$select public.v2_form_save(current_setting('t.form')::smallint,current_setting('t.data')::jsonb,'[]'::jsonb,current_setting('t.stu')::uuid,null,null,nullif(current_setting('t.entry'),'')::uuid,true)::text$q$),
    (5, 'تعديلُ المعتمد', null, $q$select public.v2_form_save(current_setting('t.form')::smallint,current_setting('t.data')::jsonb,'[]'::jsonb,current_setting('t.stu')::uuid,null,null,nullif(current_setting('t.entry'),'')::uuid,false)::text$q$),
    (6, 'امتناعٌ بلا سبب', null, $q$select public.v2_form_sign(nullif(current_setting('t.entry'),'')::uuid,current_setting('t.signer'),false,null)::text$q$),
    (7, 'إقرارُ الموقّع الأوّل', null, $q$select public.v2_form_sign(nullif(current_setting('t.entry'),'')::uuid,current_setting('t.signer'),true,null)::text$q$),
    (8, 'إلغاءٌ بلا سبب', null, $q$select public.v2_form_void(nullif(current_setting('t.entry'),'')::uuid,null)::text$q$),
    (9, 'إلغاءٌ بسبب', null, $q$select public.v2_form_void(nullif(current_setting('t.entry'),'')::uuid,'خطأٌ في التعبئة — فحص')::text$q$),
    (10, 'فتحُه بعد الإلغاء', null, $q$select 'entry='||coalesce(r->'entry'->>'status','∅') from (select public.v2_form_open(current_setting('t.form')::smallint,current_setting('t.stu')::uuid,null,null) r) z$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, coalesce(r,''), true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
select n::text as "#", left(current_setting('t.s'||n),700) as النتيجة from generate_series(1,10) n
union all select 'أ', 'signer '||coalesce(nullif(current_setting('t.signer'),''),'—')||' · data '||left(current_setting('t.data'),300);
rollback;
