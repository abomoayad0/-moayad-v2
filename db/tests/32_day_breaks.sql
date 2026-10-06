-- فحص ٣٢ · فتراتُ اليوم ولوحتُه — بالنداءات التي ترسلها yawm.js و wakeel.js (v2_now_slot).
-- كلُّه داخل begin … rollback على الطفيل. الهويّة: مفرح وكيلًا لشؤون الطلاب. لا حسابَ يُمسّ ولا حذف.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '20s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  perform set_config('t.brk',(select x->>'id' from jsonb_array_elements(public.v2_breaks(current_setting('t.school')::uuid)) x where x->>'kind'='فسحة' limit 1),true);
  for s in select * from (values
    (1, 'الفترات', $q$select string_agg((x->>'label')||' '||(x->>'kind')||' '||(x->>'starts_ar')||'—'||(x->>'ends_ar')||' '||coalesce(x->>'after_period_ar','')||' مناوبون '||(x->>'duty_now'),' · ') from jsonb_array_elements(public.v2_breaks(current_setting('t.school')::uuid)) x$q$),
    (2, 'فترةٌ تتداخل مع حصّة', $q$select public.v2_break_save(current_setting('t.school')::uuid,null,'أخرى','فحص',time '08:00',time '08:10',null,false,null,null)::text$q$),
    (3, 'فترةٌ تتداخل مع الفسحة', $q$select public.v2_break_save(current_setting('t.school')::uuid,null,'أخرى','فحص',time '09:20',time '09:30',null,false,null,null)::text$q$),
    (4, 'نوعٌ غيرُ معروف', $q$select public.v2_break_save(current_setting('t.school')::uuid,null,'غداء','فحص',time '13:30',time '13:40',null,false,null,null)::text$q$),
    (5, 'نهايةٌ قبل البداية', $q$select public.v2_break_save(current_setting('t.school')::uuid,null,'أخرى','فحص',time '13:40',time '13:30',null,false,null,null)::text$q$),
    (6, 'فترةٌ سليمةٌ بعد الانصراف', 'nb', $q$select r->>'break' from (select public.v2_break_save(current_setting('t.school')::uuid,null,'أخرى','نشاطٌ بعد الدوام — فحص',time '13:30',time '13:40',null,false,null,'فحص') r) z$q$),
    (7, 'إلغاؤها بلا سبب', $q$select public.v2_break_remove(current_setting('t.school')::uuid,nullif(current_setting('t.nb',true),'')::uuid,'')::text$q$),
    (8, 'إلغاؤها بسبب', $q$select public.v2_break_remove(current_setting('t.school')::uuid,nullif(current_setting('t.nb',true),'')::uuid,'فحص')::text$q$),
    (9, 'الآن ٠٧:٣٠', $q$select public.v2_now_slot(current_setting('t.school')::uuid,time '07:30')::text$q$),
    (10, 'الآن ٠٩:٢٠', $q$select public.v2_now_slot(current_setting('t.school')::uuid,time '09:20')::text$q$),
    (11, 'الآن ١٢:٤٠', $q$select public.v2_now_slot(current_setting('t.school')::uuid,time '12:40')::text$q$),
    (12, 'الآن ١٥:٠٠', $q$select public.v2_now_slot(current_setting('t.school')::uuid,time '15:00')::text$q$),
    (13, 'لوحةُ اليوم', $q$select (r->'settings')::text||' ‖ خطّ '||jsonb_array_length(r->'line')||' ‖ '||(r->'issues')::text||' ‖ طول '||coalesce(r->>'day_length_ar','∅') from (select public.v2_day_plan(current_setting('t.school')::uuid) r) z$q$),
    (14, 'ابنِ اليوم: معاينة (٠٧:٠٠ · ٤٥ · ٧ · فسحة ٢٠ بعد ٣ · صلاة ١٥ بعد ٧)', $q$select (r - 'plan')::text||' ‖ '||(select string_agg((x->>'label')||' '||(x->>'from')||'—'||(x->>'to'),' · ') from jsonb_array_elements(r->'plan') x) from (select public.v2_day_build(current_setting('t.school')::uuid,time '07:00',45::smallint,7::smallint,'[{"kind":"فسحة","label":"الفسحة","minutes":20,"after_period":3},{"kind":"صلاة","label":"الصلاة","minutes":15,"after_period":7}]'::jsonb,null) r) z$q$),
    (15, 'ابنِ اليوم: بغير «أقرّ»', $q$select (public.v2_day_build(current_setting('t.school')::uuid,time '07:00',45::smallint,7::smallint,'[]'::jsonb,'نعم')->>'applied')$q$),
    (16, 'ابنِ اليوم: مدّةُ حصّةٍ ١٠', $q$select public.v2_day_build(current_setting('t.school')::uuid,time '07:00',10::smallint,7::smallint,'[]'::jsonb,null)::text$q$),
    (17, 'ابنِ اليوم: «أقرّ» (داخل التراجع)', $q$select (r - 'plan')::text from (select public.v2_day_build(current_setting('t.school')::uuid,time '07:00',45::smallint,7::smallint,'[{"kind":"فسحة","label":"الفسحة","minutes":20,"after_period":3},{"kind":"صلاة","label":"الصلاة","minutes":15,"after_period":7}]'::jsonb,'أقرّ') r) z$q$),
    (18, 'لوحةُ اليوم بعد التثبيت', $q$select (r->'settings'->>'assembly_ar')||' · حدّ '||(r->'settings'->>'late_cutoff_ar')||' · '||(r->'issues')::text||' · خطّ '||jsonb_array_length(r->'line') from (select public.v2_day_plan(current_setting('t.school')::uuid) r) z$q$)
  ) v(n,l,k,q) order by n loop
    begin execute s.q into r;
      if s.k is not null then perform set_config('t.'||s.k, coalesce(r,''), true); end if;
      r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
select n::text as "#", left(current_setting('t.s'||n),900) as النتيجة from generate_series(1,18) n;
rollback;
