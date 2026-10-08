-- فحص ٣٦ · سجلُّ الأفعال (الجسورُ الأربعة تقيّد نجاحَها) · v2_action_log · page_ar · ملفُّ الإحالة بآخر الرصدات ومجموعها
-- داخل begin … rollback. التهيئةُ الوحيدة: تقديمُ final_at دقيقةً ليقع الرصدُ بعد الاعتماد في معاملةٍ واحدة
begin;
set local lock_timeout = '5s';
set local statement_timeout = '40s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
select set_config('t.stu','d4c11fbb-c7d1-4242-954b-519d96aaa9b3',true);
select set_config('t.pl','',true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  perform set_config('t.n0', (select jsonb_array_length(public.v2_action_log(current_setting('t.school')::uuid,current_setting('t.stu')::uuid,500)))::text, true);
  for s in select * from (values
    (1, 'الرصدات ١–٤', $q$select string_agg(z, ' · ') from (select set_config('t.r'||k, public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,k::smallint)->>'record', true) is not null and true as ok, k::text z from generate_series(1,4) k) q$q$),
    (2, 'اتّصالٌ: ردّ وعلم', $q$select public.v2_contact_log(current_setting('t.stu')::uuid,null,'هاتف','ردّ وعلم','علم',null,null,null)->>'note'$q$),
    (3, 'اتّصالٌ مرفوض (بلا ما دار)', $q$select public.v2_contact_log(current_setting('t.stu')::uuid,null,'هاتف','ردّ وعلم',null,null,null,null)::text$q$),
    (4, 'خطّةٌ ثمّ رأيٌ ثمّ اعتماد', $q$select (set_config('t.pl', public.v2_plan_write(current_setting('t.stu')::uuid,current_setting('t.r4')::uuid,null,null,'ينام','',null,null,null,null,'ينتبه',E'خطوة ١\nخطوة ٢',null,null)->>'plan', true) is not null)::text||' · '||(public.v2_plan_opinion(nullif(current_setting('t.pl'),'')::uuid,'teacher','رأي')->>'ok')||' · '||(public.v2_plan_final(nullif(current_setting('t.pl'),'')::uuid,'أعتمد')->>'note')$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
update v2.behavior_plans set final_at = now() - interval '1 minute' where id::text = current_setting('t.pl');
set local role authenticated;
do $$ declare s record; r text; begin
  for s in select * from (values
    (5, 'رصدةٌ بعد الاعتماد', $q$select public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,5::smallint)->>'occurrence_ar'$q$),
    (6, 'الإحالة ⇐ الملفّ', $q$select (r->'file'->>'occurrences_ar')||' · latest '||(r->'file'->>'latest_ar')||' · total '||(r->'file'->>'total_ar') from (select public.v2_refer_committee(current_setting('t.r4')::uuid,null,'لم يستجب','دراسةُ حاله') r) z$q$),
    (7, 'v2_action_log للطالب (الجديدُ فقط)', $q$select (jsonb_array_length(r) - current_setting('t.n0')::int)::text||' جديدة ‖ '||(select string_agg((x->>'action')||' «'||(x->>'action_ar')||'» '||coalesce(x->>'by','∅')||' · '||coalesce(x->>'role','∅')||' · '||coalesce(x->>'student','∅')||' · '||coalesce((x->'detail')::text,'∅'),' ‖ ') from (select x from jsonb_array_elements(r) x limit 8) y) from (select public.v2_action_log(current_setting('t.school')::uuid,current_setting('t.stu')::uuid,500) r) z$q$),
    (8, 'v2_action_log بحدّ ٣', $q$select jsonb_array_length(public.v2_action_log(current_setting('t.school')::uuid,null,3))::text$q$),
    (9, 'v2_action_log لمدرسةٍ أخرى', $q$select public.v2_action_log('f789f9ea-e474-49bc-86e0-3449258815f8'::uuid,null,3)::text$q$),
    (10, 'v2_problems: page_ar', $q$select string_agg(x->>'page_ar',' · ') from (select x from jsonb_array_elements(public.v2_problems(current_setting('t.school')::uuid,1::smallint)) x limit 3) z$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
set local request.jwt.claims = '{"sub":"c62d924e-b3a5-4142-b06b-88836829addb","role":"authenticated"}';
do $$ declare r text; begin
  begin r := 'نفذ: '||left(public.v2_action_log(current_setting('t.school')::uuid,current_setting('t.stu')::uuid,3)::text,120);
  exception when others then r := 'رُفض: '||sqlerrm; end;
  perform set_config('t.s11','وليُّ الأمر يقرأ سجلَّ الأفعال ⇐ '||r,true);
end $$;
reset role;
select n::text as "#", left(current_setting('t.s'||n),1500) as النتيجة from generate_series(1,11) n;
rollback;
