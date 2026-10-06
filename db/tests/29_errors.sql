-- فحص ٢٩ · لوحةُ الأخطاء — بالنداءات التي ترسلها errors.js. كلُّه داخل begin … rollback. لا حسابَ يُمسّ ولا حذف.
-- الهويّات: مفرح (يملك view_errors) · ووليُّ الأمر بندر (لا يملكه).
begin;
set local lock_timeout = '5s';
set local statement_timeout = '20s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  perform set_config('t.err',coalesce((select id::text from public.v2_errors(30,'error') where not fixed limit 1),''),true);
  for s in select * from (values
    (1, 'مفرح · view_errors', $q$select coalesce(r->'can'->>'view_errors','—') from (select public.v2_me() r) z$q$),
    (2, 'مفرح · أسبوعٌ كلُّه', $q$select count(*)||' · أعطاب '||count(*) filter (where kind='error')||' · حرّاس '||count(*) filter (where kind='guard')||' · أُصلح '||count(*) filter (where fixed) from public.v2_errors(7,null)$q$),
    (3, 'مفرح · يومٌ أعطابُه', $q$select count(*)::text from public.v2_errors(1,'error')$q$),
    (4, 'مفرح · شهرٌ حرّاسُه', $q$select count(*)::text from public.v2_errors(30,'guard')$q$),
    (5, 'مفرح · سطرٌ واحد بمفاتيحه', $q$select coalesce((select row_to_json(x)::text from public.v2_errors(30,null) x limit 1),'—')$q$),
    (6, 'مفرح · يسمه أُصلح', $q$select coalesce(public.v2_error_fixed(nullif(current_setting('t.err'),'')::uuid,'فحص ٢٩')::text,'—')$q$),
    (7, 'مفرح · بعد الوسم', $q$select coalesce((select fixed::text from public.v2_errors(30,'error') where id=nullif(current_setting('t.err'),'')::uuid),'ليس فيه')$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"c62d924e-b3a5-4142-b06b-88836829addb","role":"authenticated"}';
do $$ declare r text; begin
  begin r := 'نفذ: '||(select count(*) from public.v2_errors(7,null))::text; exception when others then r := 'رُفض: '||sqlerrm; end;
  perform set_config('t.s8', 'بندر (وليُّ أمر) · يقرأ الأخطاء ⇐ '||r, true);
  begin r := 'نفذ: '||coalesce(public.v2_error_fixed(nullif(current_setting('t.err'),'')::uuid,null)::text,'—'); exception when others then r := 'رُفض: '||sqlerrm; end;
  perform set_config('t.s9', 'بندر (وليُّ أمر) · يسم خطأً ⇐ '||r, true);
end $$;
reset role;
select n::text as "#", left(current_setting('t.s'||n),900) as النتيجة from generate_series(1,9) n
union all select 'أ', 'err '||coalesce(nullif(current_setting('t.err'),''),'—');
rollback;
