-- فحص ٣٩ · صناديقُ النماذج (v2_my_form_inbox · v2_form_inbox_read) · موانعُ الإلغاء (v2_void_blockers) · حارسُ ملاحظة المسحوب · قائمةُ المتبقّي بسجلّ الصادر
-- كلُّه داخل begin…rollback — يُقرأ بهويّة الموجّه وطالبٍ ووكيلٍ ووليِّ أمر، ولا يبقى منه شيء
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
-- تهيئة: أرقامٌ تُقرأ بلا RLS
do $$ begin
  perform set_config('t.stu_inbox',(select i.id::text from v2.form_inbox i join v2.students s on s.id=i.student_id where i.to_kind='student' and s.user_id='ff4268af-1706-4b2f-a4bf-18042beab878' limit 1),true);
  perform set_config('t.rec_first',coalesce((select br.id::text from v2.behavior_records br where br.school_id::text=current_setting('t.school') and br.status<>'voided'
      and exists (select 1 from v2.behavior_records x where x.student_id=br.student_id and x.problem_id=br.problem_id and x.year_id=br.year_id and x.status<>'voided' and x.occurrence_no>br.occurrence_no)
      order by br.occurrence_no limit 1),''),true);
  perform set_config('t.g_void',coalesce((select fi.id::text from v2.form_inbox fi join v2.form_entries e on e.id=fi.entry_id join v2.guardians g on g.id=fi.guardian_id where fi.to_kind='guardian' and e.status='void' and g.user_id='c62d924e-b3a5-4142-b06b-88836829addb' limit 1),''),true);
end $$;
-- ① الموجّه
set local role authenticated;
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
do $$ declare r jsonb; begin
  r := public.v2_my_form_inbox();
  perform set_config('t.c_inbox', r->'rows'->0->>'inbox', true);
  perform set_config('t.s1','① الموجّه: v2_my_form_inbox ⇐ '||(r->>'who_ar')||' · count '||(r->>'count')||' · unread '||(r->>'unread')||' · أنواعُه '||(select string_agg(distinct x->>'to_kind_ar',' / ') from jsonb_array_elements(r->'rows') x)||' · سرّيّة '||(select count(*) from jsonb_array_elements(r->'rows') x where (x->>'is_secret')::boolean)||' · مسحوبة '||(select count(*) from jsonb_array_elements(r->'rows') x where (x->>'withdrawn')::boolean)||' · أوّلُها: '||(r->'rows'->0->>'title_ar')||' — '||(r->'rows'->0->>'student_ar')||' · '||(r->'rows'->0->>'delivered_h')||' · حقول '||jsonb_array_length(coalesce(r->'rows'->0->'fields_kv','[]'))||' ‖ '||(r->>'note_ar'),true);
exception when others then perform set_config('t.s1','① الموجّه ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s2','② الموجّه يُعلّم أوّلَها مقروءًا ⇐ '||public.v2_form_inbox_read(nullif(current_setting('t.c_inbox'),'')::uuid)::text,true);
exception when others then perform set_config('t.s2','② ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s3','③ الموجّه يُعلّم صفَّ طالب ⇐ '||public.v2_form_inbox_read(nullif(current_setting('t.stu_inbox'),'')::uuid)::text,true);
exception when others then perform set_config('t.s3','③ الموجّه يُعلّم صفَّ طالب ⇐ رُفض: '||sqlerrm,true); end $$;
-- ② الطالب بحسابه
set local request.jwt.claims = '{"sub":"ff4268af-1706-4b2f-a4bf-18042beab878","role":"authenticated"}';
do $$ declare r jsonb; begin
  r := public.v2_my_form_inbox();
  perform set_config('t.s4','④ الطالب: v2_my_form_inbox ⇐ '||(r->>'who_ar')||' · count '||(r->>'count')||' · unread '||(r->>'unread')||' · أنواعُه '||coalesce((select string_agg(distinct x->>'to_kind',',') from jsonb_array_elements(r->'rows') x),'∅')||' · مسحوبة '||(select count(*) from jsonb_array_elements(r->'rows') x where (x->>'withdrawn')::boolean)||' ‖ العناوين: '||coalesce((select string_agg(x->>'title_ar',' | ') from jsonb_array_elements(r->'rows') x),'∅'),true);
exception when others then perform set_config('t.s4','④ الطالب ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s5','⑤ الطالب يُعلّم صفَّ الموجّه ⇐ '||public.v2_form_inbox_read(nullif(current_setting('t.c_inbox'),'')::uuid)::text,true);
exception when others then perform set_config('t.s5','⑤ الطالب يُعلّم صفَّ الموجّه ⇐ رُفض: '||sqlerrm,true); end $$;
-- ③ الوكيل
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare r jsonb; begin
  r := public.v2_my_form_inbox();
  perform set_config('t.s6','⑥ الوكيل: صندوقُه ⇐ '||(r->>'who_ar')||' · count '||(r->>'count'),true);
exception when others then perform set_config('t.s6','⑥ الوكيل ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; first text; begin
  r := public.v2_void_blockers(nullif(current_setting('t.rec_first'),'')::uuid);
  first := r->'blockers'->-1->>'record';
  perform set_config('t.last', r->'blockers'->0->>'record', true);
  perform set_config('t.s7','⑦ v2_void_blockers لرصدةٍ بعدها غيرُها ⇐ '||(r->>'problem_ar')||' · '||(r->>'occurrence_ar')||' · can_void '||(r->>'can_void')||' · already '||(r->>'already_void')||' · confirm '||(r->>'confirm_word')||' · موانع '||jsonb_array_length(r->'blockers')||' ['||(select string_agg((x->>'label_ar')||' · '||(x->>'state_ar')||' · id '||left(x->>'record',8),' | ') from jsonb_array_elements(r->'blockers') x)||'] ‖ '||coalesce(r->>'why_ar','∅'),true);
exception when others then perform set_config('t.s7','⑦ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_void_blockers(nullif(current_setting('t.last'),'')::uuid);
  perform set_config('t.s8','⑧ v2_void_blockers لآخرها ⇐ '||(r->>'occurrence_ar')||' · can_void '||(r->>'can_void')||' · موانع '||jsonb_array_length(r->'blockers')||' · why '||coalesce(r->>'why_ar','∅'),true);
exception when others then perform set_config('t.s8','⑧ ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_open_records(current_setting('t.school')::uuid);
  perform set_config('t.s9','⑨ v2_open_records ⇐ count '||(r->>'count')||' · waiting '||(r->>'waiting')||' · waiting_outgoing '||coalesce(r->>'waiting_outgoing','∅')||' ‖ '||(r->>'summary_ar')||' ‖ صفٌّ بسجلّ الصادر: '||coalesce((select (x->>'why_ar') from jsonb_array_elements(r->'rows') x where (x->>'waits_outgoing')::boolean limit 1),'∅'),true);
exception when others then perform set_config('t.s9','⑨ ⇐ رُفض: '||sqlerrm,true); end $$;
-- ④ وليُّ الأمر: ملاحظةٌ على مسحوب
set local request.jwt.claims = '{"sub":"c62d924e-b3a5-4142-b06b-88836829addb","role":"authenticated"}';
do $$ begin
  if nullif(current_setting('t.g_void'),'') is null then
    perform set_config('t.s10','⑩ وليُّ الأمر (بندر): لا نموذجَ مسحوبًا في صندوقه — فلم يُجرَّب الحارس',true);
  else
    perform set_config('t.s10','⑩ ملاحظةٌ على مسحوب ⇐ '||public.v2_guardian_form_note(current_setting('t.g_void')::uuid,'رأيي')::text,true);
  end if;
exception when others then perform set_config('t.s10','⑩ ملاحظةٌ على مسحوب ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ begin
  perform set_config('t.s11','⑪ صندوقُ بندر: مسحوبة '||(select count(*) from public.v2_guardian_forms() g where g.title_ar like '(مسحوب)%')||' · منها يُطالَب بتوقيعٍ أو ردّ '||(select count(*) from public.v2_guardian_forms() g where g.title_ar like '(مسحوب)%' and (g.needs_sign or g.needs_reply))||' · والمجموع '||(select count(*) from public.v2_guardian_forms()),true);
exception when others then perform set_config('t.s11','⑪ ⇐ رُفض: '||sqlerrm,true); end $$;
reset role;
select n, current_setting('t.s'||n, true) as result from generate_series(1,11) n;
rollback;
