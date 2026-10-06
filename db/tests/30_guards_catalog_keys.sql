-- فحص ٣٠ · ما أصلحته القاعدة: حرّاسُ الوقت العربيّة · v2_forms_catalog · مفتاحا jadwal و delegation.
-- الإصدار ٢: أصلحت القاعدةُ حارسَ الوسيلة والنتيجة (is null) — فأُعيد مرّةً، وأُضيف السطر ٨ (بلا نتيجة).
-- كلُّه داخل begin … rollback. الهويّات: مفرح (وكيلُ شؤون الطلاب) · سعيد (الموجّه). لا حسابَ يُمسّ ولا حذف.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '20s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true), set_config('t.d',current_date::text,true),
       set_config('t.stu','5f5e70d0-e519-4e26-b254-64885d0fbb6a',true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, 'مفرح · وصولٌ بلا وقت', $q$select public.v2_record_arrival(current_setting('t.stu')::uuid,current_setting('t.d')::date,null,'enter_class',null,null)::text$q$),
    (2, 'مفرح · انصرافٌ بلا وقت', $q$select (select row_to_json(x)::text from public.v2_record_dismissal(current_setting('t.stu')::uuid,current_setting('t.d')::date,null,null) x)$q$),
    (3, 'مفرح · اتّصالٌ بلا وسيلة', $q$select public.v2_contact_log(current_setting('t.stu')::uuid,null,null,'لم يردّ','فحص',null,null)::text$q$),
    (4, 'مفرح · كتالوجُ النماذج', $q$select jsonb_array_length(r)||' ‖ '||(select string_agg(g||' '||c,' · ') from (select x->>'group' g, count(*) c from jsonb_array_elements(r) x group by 1 order by 1) z)||' ‖ '||(r->0)::text from (select public.v2_forms_catalog(current_setting('t.school')::uuid) r) z$q$),
    (5, 'مفرح · كتالوجُ مدرسةٍ ليست له', $q$select jsonb_array_length(public.v2_forms_catalog('00000000-0000-0000-0000-000000000000'::uuid))::text$q$),
    (6, 'مفرح · المفاتيح', $q$select 'jadwal='||coalesce(r->'can'->>'jadwal','—')||' · delegation='||coalesce(r->'can'->>'delegation','—')||' · manage_settings='||coalesce(r->'can'->>'manage_settings','—')||' · fill_form='||coalesce(r->'can'->>'fill_form','—')||' · wakeel='||coalesce(r->'can'->>'wakeel','—') from (select public.v2_me() r) z$q$),
    (8, 'مفرح · اتّصالٌ بلا نتيجة', $q$select public.v2_contact_log(current_setting('t.stu')::uuid,null,'هاتف',null,'فحص',null,null)::text$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ declare r text; begin
  begin select 'jadwal='||coalesce(x->'can'->>'jadwal','—')||' · delegation='||coalesce(x->'can'->>'delegation','—')||' · manage_settings='||coalesce(x->'can'->>'manage_settings','—')||' · muwajjih='||coalesce(x->'can'->>'muwajjih','—') into r from (select public.v2_me() x) z; r := 'نفذ: '||r;
  exception when others then r := 'رُفض: '||sqlerrm; end;
  perform set_config('t.s7', 'سعيد · المفاتيح ⇐ '||r, true);
end $$;
reset role;
select n::text as "#", left(current_setting('t.s'||n),600) as النتيجة from generate_series(1,8) n;
rollback;
