-- فحص ٤٤ · تكليفُ ⑦: بطاقةُ الوارد (v2_mail_card) بشكل مرفقاتها الجديد ومن يفتحها · سجلُّ الوارد مُقفلٌ على المعلّم
--          · بحثُ الطلّاب مقصورٌ على فصول المعلّم (scoped · sections_n) · ورفضُ مسار الشاهد في v2_entry_file
-- 🔑 الحرّاسُ تُفحص بحساباتٍ حقيقيّة (معلّمُ موادّ · موجّه · مساعدٌ إداريّ · طالب) — لا بحساب المالك
-- وكلُّه داخل begin…rollback — والتوجيهُ إلى المعلّم تهيئةٌ تُمحى
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
-- تهيئة: أرقامٌ تُقرأ بلا RLS
do $$ declare tp uuid; begin
  select a.person_id into tp from v2.app_users a where a.id='5e17dd28-15ef-4c80-b7ba-0cb3d9e4141d';
  perform set_config('t.tp', coalesce(tp::text,''), true);
  -- واردٌ عاديٌّ غيرُ مُقفلٍ لم يُوجَّه إلى المعلّم بشيء — وما له مرفقٌ مقدَّم
  perform set_config('t.m', coalesce((select m.id::text from v2.incoming_mail m
     where m.school_id::text=current_setting('t.school') and m.secrecy='عادي' and m.status<>'closed'
       and not exists (select 1 from v2.mail_items i join v2.mail_targets t on t.item_id=i.id where i.mail_id=m.id and t.person_id=tp)
       and not exists (select 1 from v2.mail_items i join v2.mail_followups f on f.item_id=i.id where i.mail_id=m.id and f.person_id=tp)
       and not exists (select 1 from v2.mail_acknowledgements ak where ak.mail_id=m.id and ak.person_id=tp)
     order by (select count(*) from v2.mail_attachments a where a.mail_id=m.id) desc, m.received_on_g desc limit 1),''), true);
  perform set_config('t.m_att', (select count(*)::text from v2.mail_attachments a where a.mail_id::text=current_setting('t.m')), true);
  -- مشاركةُ الطالب ذي البوّابة في فرصةٍ مُغلقةٍ لم تُقرّ
  perform set_config('t.entry', coalesce((select e.id::text from v2.merit_entries e join v2.merit_opportunities o on o.id=e.opp_id
     join v2.students s on s.id=e.student_id where s.user_id='ff4268af-1706-4b2f-a4bf-18042beab878' and o.state<>'مفتوحة' and e.verdict is null limit 1),''), true);
end $$;
set local role authenticated;
-- ① الموجّه: يقرأ السجلَّ ويفتح البطاقة
set local request.jwt.claims = '{"sub":"52bc11f6-8e82-44cd-9f4d-e9bf43aee128","role":"authenticated"}';
select public.v2_act_as('counselor', current_setting('t.school')::uuid);
do $$ begin
  perform set_config('t.s1','① الموجّه: v2_mail_inbox ⇐ '||(select count(*) from public.v2_mail_inbox(current_setting('t.school')::uuid,null,365))||' واردًا',true);
exception when others then perform set_config('t.s1','① الموجّه: v2_mail_inbox ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_mail_card(nullif(current_setting('t.m'),'')::uuid);
  perform set_config('t.s2','② الموجّه: v2_mail_card ⇐ ok '||(r->>'ok')||' · '||(r->'mail'->>'subject')||' · مرفقات '||jsonb_array_length(r->'attachments')||' (في الجدول '||current_setting('t.m_att')||') · مفاتيحُ أوّلها: '||coalesce((select string_agg(k,',' order by k) from jsonb_object_keys(r->'attachments'->0) k),'∅')||' · بنود '||jsonb_array_length(r->'items'),true);
exception when others then perform set_config('t.s2','② الموجّه: v2_mail_card ⇐ رُفض: '||sqlerrm,true); end $$;
-- ② معلّمُ الموادّ: لا سجلّ · ولا بطاقةَ ما لم يُوجَّه إليه
set local request.jwt.claims = '{"sub":"5e17dd28-15ef-4c80-b7ba-0cb3d9e4141d","role":"authenticated"}';
do $$ begin
  perform set_config('t.s3','③ المعلّم: v2_mail_inbox ⇐ '||(select count(*) from public.v2_mail_inbox(current_setting('t.school')::uuid,null,365))||' واردًا — قُبل',true);
exception when others then perform set_config('t.s3','③ المعلّم: v2_mail_inbox ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_mail_card(nullif(current_setting('t.m'),'')::uuid);
  perform set_config('t.s4','④ المعلّم: بطاقةُ واردٍ لم يُوجَّه إليه ⇐ قُبل: '||(r->>'ok'),true);
exception when others then perform set_config('t.s4','④ المعلّم: بطاقةُ واردٍ لم يُوجَّه إليه ⇐ رُفض: '||sqlerrm,true); end $$;
-- ③ تهيئة: الوكيلُ يوجّه بندًا إلى المعلّم باسمه
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare r jsonb; begin
  r := public.v2_mail_direct(nullif(current_setting('t.m'),'')::uuid,
    jsonb_build_array(jsonb_build_object('text','بندُ فحصٍ يُمحى','kind','تكليف',
      'targets', jsonb_build_array(jsonb_build_object('kind','person','person',current_setting('t.tp'),'role','معلّم')))));
  perform set_config('t.s5','⑤ تهيئة: توجيهُ بندٍ إلى المعلّم ⇐ '||(r->>'note_ar'),true);
exception when others then perform set_config('t.s5','⑤ تهيئة: توجيهٌ ⇐ رُفض: '||sqlerrm,true); end $$;
-- ④ المعلّم بعد التوجيه
set local request.jwt.claims = '{"sub":"5e17dd28-15ef-4c80-b7ba-0cb3d9e4141d","role":"authenticated"}';
do $$ declare r jsonb; begin
  r := public.v2_mail_card(nullif(current_setting('t.m'),'')::uuid);
  perform set_config('t.s6','⑥ المعلّم: البطاقةُ بعد توجيهها إليه ⇐ ok '||(r->>'ok')||' · my_followups_n '||(r->>'my_followups_n')||' · متابعاتٌ له '||(select count(*) from jsonb_array_elements(r->'items') i, jsonb_array_elements(case jsonb_typeof(i->'followups') when 'array' then i->'followups' else '[]'::jsonb end) f where (f->>'mine')::boolean),true);
exception when others then perform set_config('t.s6','⑥ المعلّم: البطاقةُ بعد توجيهها ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare n int; k text; begin
  select count(*) into n from public.v2_mail_my_tasks(current_setting('t.school')::uuid) t where t.text_ar='بندُ فحصٍ يُمحى';
  select string_agg(a.attname,',' order by a.attnum) into k from unnest((select proargnames from pg_proc where oid='public.v2_mail_my_tasks'::regproc)) with ordinality a(attname,attnum) where a.attnum>1;
  perform set_config('t.s7','⑦ المعلّم: v2_mail_my_tasks ⇐ بندُ الفحص فيه '||n||' · أعمدتُه: '||k,true);
exception when others then perform set_config('t.s7','⑦ المعلّم: v2_mail_my_tasks ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_students_find(null,null,null,60,current_setting('t.school')::uuid);
  perform set_config('t.s8','⑧ المعلّم: v2_students_find بلا نصّ ⇐ scoped '||(r->>'scoped')||' · sections_n '||coalesce(r->>'sections_n','null')||' · '||(r->>'summary_ar')||' ‖ '||(r->>'note_ar'),true);
exception when others then perform set_config('t.s8','⑧ المعلّم: v2_students_find ⇐ رُفض: '||sqlerrm,true); end $$;
do $$ declare r jsonb; begin
  r := public.v2_students_find('حس',null,null,60,current_setting('t.school')::uuid);
  perform set_config('t.s9','⑨ المعلّم: البحثُ «حس» ⇐ '||(r->>'summary_ar')||' · فصولُ النتائج: '||coalesce((select string_agg(distinct (x->>'grade')||'/'||(x->>'section'),' ') from jsonb_array_elements(r->'rows') x),'∅'),true);
exception when others then perform set_config('t.s9','⑨ ⇐ رُفض: '||sqlerrm,true); end $$;
-- ⑤ المساعدُ الإداريّ: المدرسةُ كلُّها
set local request.jwt.claims = '{"sub":"fad7dfa7-8f6f-4c5b-9fbf-c0a2c308476a","role":"authenticated"}';
do $$ declare r jsonb; begin
  r := public.v2_students_find(null,null,null,60,current_setting('t.school')::uuid);
  perform set_config('t.s10','⑩ المساعد: v2_students_find ⇐ scoped '||(r->>'scoped')||' · sections_n '||coalesce(r->>'sections_n','null')||' · '||(r->>'summary_ar')||' ‖ '||(r->>'note_ar'),true);
exception when others then perform set_config('t.s10','⑩ المساعد ⇐ رُفض: '||sqlerrm,true); end $$;
-- ⑥ الطالب: شاهدٌ بمسارٍ خاطئ
set local request.jwt.claims = '{"sub":"ff4268af-1706-4b2f-a4bf-18042beab878","role":"authenticated"}';
do $$ begin
  if nullif(current_setting('t.entry'),'') is null then
    perform set_config('t.s11','⑪ الطالب: لا مشاركةَ له في فرصةٍ مُغلقةٍ لم تُقرّ — فلم يُجرَّب رفضُ المسار',true);
  else
    perform set_config('t.s11','⑪ الطالب: v2_entry_file بمسارٍ خاطئ ⇐ قُبل: '||public.v2_entry_file(current_setting('t.entry')::uuid,'فعلتُ','wrong/path.pdf','وصف')::text,true);
  end if;
exception when others then perform set_config('t.s11','⑪ الطالب: v2_entry_file بمسارٍ خاطئ ⇐ رُفض: '||sqlerrm,true); end $$;
reset role;
select n, current_setting('t.s'||n, true) as result from generate_series(1,11) n;
rollback;
