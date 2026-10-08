-- فحص ٣٨ · الأبوابُ الثمانيةُ الجديدة (تكليفُ الشاشات ②) — كلُّه داخل begin…rollback فلا يبقى منه شيء
-- الهويّة · قائمةُ المتبقّي · الإلغاء · حالُ الرصدة واستيفاؤها · ما بعد السلّم · حارسُ الخطّة · حارسُ التبليغ والنفيُ المعروض · نقلُ الفصل
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';
select set_config('t.school','7a847bb1-9b14-41ad-b9ba-7c8dee61a992',true);
select set_config('t.stu','04335119-5a39-45ad-ac13-4c1988c3034a',true);
set local role authenticated;
set local request.jwt.claims = '{"sub":"11be0946-ff39-4eb7-8a74-023b580479be","role":"authenticated"}';
select public.v2_act_as('deputy_students', current_setting('t.school')::uuid);
do $$ declare s record; r text; begin
  for s in select * from (values
    (1, '⑧ v2_brand_tokens', $q$select 'ألوان '||jsonb_array_length(r->'colors')||' · خطوط '||jsonb_array_length(r->'fonts')||' · قواعد '||jsonb_array_length(r->'logo_rules')||' ‖ '||(select string_agg((x->>'key')||'='||(x->>'value'),' · ') from jsonb_array_elements(r->'colors') x)||' ‖ '||(select string_agg((x->>'key')||'='||(x->>'value')||' بديل:'||coalesce(x->>'is_substitute','∅')||' أصل:'||coalesce(x->>'original','∅'),' · ') from jsonb_array_elements(r->'fonts') x)||' ‖ source '||coalesce(r->>'source_ar','∅') from (select public.v2_brand_tokens() r) z$q$),
    (2, '⑧ v2_branding', $q$select (select string_agg(k,',' order by k) from jsonb_object_keys(r) k)||' ‖ primary '||coalesce(r->>'primary_color','∅')||' · accent '||coalesce(r->>'accent_color','∅') from (select public.v2_branding(current_setting('t.school')::uuid) r) z$q$),
    (3, '① v2_open_records قبل', $q$select (set_config('t.n0', r->>'count', true) is not null)::text||' count '||(r->>'count')||' · waiting '||(r->>'waiting')||' · rows '||jsonb_array_length(r->'rows')||' ‖ '||(r->>'summary_ar')||' ‖ '||(r->>'note_ar') from (select public.v2_open_records(current_setting('t.school')::uuid) r) z$q$),
    (4, '④ الرصدة ١ (٤٣ ح١)', $q$select (set_config('t.r1', r->>'record', true) is not null)::text||' '||(r->>'occurrence_ar') from (select public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,1::smallint) r) z$q$),
    (5, '④ الرصدة ٢', $q$select (set_config('t.r2', r->>'record', true) is not null)::text||' '||(r->>'occurrence_ar') from (select public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,2::smallint) r) z$q$),
    (6, '④ الرصدة ٣', $q$select (set_config('t.r3', r->>'record', true) is not null)::text||' '||(r->>'occurrence_ar') from (select public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,3::smallint) r) z$q$),
    (7, '④ الرصدة ٤', $q$select (set_config('t.r4', r->>'record', true) is not null)::text||' '||(r->>'occurrence_ar') from (select public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,4::smallint) r) z$q$),
    (8, '④ الرصدة ٥ (بعد نهاية السلّم)', $q$select (set_config('t.r5', r->>'record', true) is not null)::text||' '||(r->>'occurrence_ar')||' · step '||coalesce(r->>'step','∅')||' · deducted '||coalesce(r->>'deducted','∅')||' ‖ auto '||coalesce((r->'auto')::text,'∅') from (select public.v2_record_behavior(current_setting('t.stu')::uuid,43,null,null,5::smallint) r) z$q$),
    (9, '⑦ الرصدة على ٥٠ (درجة ٣ · فيها تبليغ)', $q$select (set_config('t.rp', r->>'record', true) is not null)::text||' '||(r->>'headline')||' ‖ auto '||coalesce((r->'auto')::text,'∅') from (select public.v2_record_behavior(current_setting('t.stu')::uuid,50,null,null,1::smallint) r) z$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
-- أرقامُ المهامّ تُقرأ بلا RLS (تهيئةٌ للفحص لا جسر)
reset role;
do $$ begin
  perform set_config('t.bl',coalesce((select id::text from v2.behavior_tasks where record_id::text=nullif(current_setting('t.r5'),'') and kind='beyond_ladder' limit 1),''),true);
  perform set_config('t.po',coalesce((select id::text from v2.behavior_tasks where record_id::text=nullif(current_setting('t.rp'),'') and kind='police' limit 1),''),true);
  perform set_config('t.ng',coalesce((select id::text from v2.behavior_tasks where record_id::text=nullif(current_setting('t.rp'),'') and kind='notify_guardian' and status='open' limit 1),''),true);
  perform set_config('t.mv',coalesce((select id::text from v2.behavior_tasks where record_id::text=nullif(current_setting('t.rp'),'') and kind='move_class' limit 1),''),true);
  perform set_config('t.r1open',coalesce((select string_agg(id::text,',') from v2.behavior_tasks where record_id::text=nullif(current_setting('t.r1'),'') and status='open'),''),true);
  perform set_config('t.s10','④ مهامّ الرصدة ٥ ⇐ '||coalesce((select string_agg(kind||'/'||status||'/'||coalesce(origin,'∅')||'/'||evidence_kind,' · ' order by ord) from v2.behavior_tasks where record_id::text=nullif(current_setting('t.r5'),'')),'لا شيء'),true);
  perform set_config('t.s11','⑦ مهامّ رصدة ٥٠ ⇐ '||coalesce((select string_agg(kind||'/'||status,' · ' order by ord) from v2.behavior_tasks where record_id::text=nullif(current_setting('t.rp'),'')),'لا شيء'),true);
  -- ⑤ تهيئة: خطّةٌ معتمدةٌ على الرصدة ١ بخطوتين
  begin
    insert into v2.behavior_plans(record_id,student_id,status,school_id,final_at,steps)
    values (nullif(current_setting('t.r1'),'')::uuid,current_setting('t.stu')::uuid,'final',current_setting('t.school')::uuid,now(),array['يُجلَس في الصفّ الأوّل','يُكلَّف بمهمّةٍ في الحصّة']);
    perform set_config('t.s12','⑤ تهيئة: خطّةٌ معتمدةٌ بخطوتين على الرصدة ١ ⇐ نفذ',true);
  exception when others then perform set_config('t.s12','⑤ تهيئة ⇐ رُفض: '||sqlerrm,true); end;
end $$;
set local role authenticated;
do $$ declare s record; r text; begin
  for s in select * from (values
    (13, '③ بطاقةُ بند ما بعد السلّم', $q$select 'origin '||coalesce(r->'task'->>'origin','∅')||' · door '||coalesce(r->>'door','∅')||' · proposal '||coalesce((r->'proposal')::text,'∅')||' · grounds '||coalesce(r->>'grounds_ar','∅')||' · blocked '||coalesce(r->>'blocked_ar','∅')||' · settled '||coalesce(r->>'settled_ar','∅') from (select public.v2_task_card(nullif(current_setting('t.bl'),'')::uuid) r) z$q$),
    (14, '⑥ بطاقةُ بند التبليغ (والإشعارُ مفتوح)', $q$select 'door '||coalesce(r->>'door','∅')||' ‖ proposal '||coalesce((r->'proposal')::text,'∅')||' ‖ grounds '||coalesce(r->>'grounds_ar','∅')||' ‖ blocked '||coalesce(r->>'blocked_ar','∅')||' ‖ settled '||coalesce(r->>'settled_ar','∅') from (select public.v2_task_card(nullif(current_setting('t.po'),'')::uuid) r) z$q$),
    (15, '⑥ «بلّغتُ» قبل الإشعار', $q$select public.v2_task_evidence(nullif(current_setting('t.po'),'')::uuid,current_date,'بُلّغت الجهة',null,null,null,null,null)::text$q$),
    (16, '⑥ إقرارُ النفي المعروض (v2_task_skip)', $q$select coalesce(public.v2_task_skip(nullif(current_setting('t.po'),'')::uuid,'عايَنتُ الواقعةَ: لا إصابةَ ولا مضبوطَ — فلا موجبَ لتبليغ الجهات الأمنيّة')::text,'void')$q$),
    (17, '⑥ البطاقةُ بعد النفي', $q$select 'proposal '||coalesce((r->'proposal')::text,'∅')||' ‖ settled '||coalesce(r->>'settled_ar','∅') from (select public.v2_task_card(nullif(current_setting('t.po'),'')::uuid) r) z$q$),
    (18, '⑤ خطّةٌ مطابقةٌ للمعتمدة (الرصدة ٢)', $q$select public.v2_plan_write(current_setting('t.stu')::uuid,nullif(current_setting('t.r2'),'')::uuid,null,null,'ينام','ينام','سهر','—','راحة','—','يقظة',E'يُكلَّف بمهمّةٍ في الحصّة\nيُجلَس في الصفّ الأوّل',null,null)::text$q$),
    (19, '⑤ خطّةٌ مغيَّرة (الرصدة ٢)', $q$select public.v2_plan_write(current_setting('t.stu')::uuid,nullif(current_setting('t.r2'),'')::uuid,null,null,'ينام','ينام','سهر','—','راحة','—','يقظة',E'يُجلَس في الصفّ الأوّل\nيُتّفق مع وليّ أمره على موعد نومه',null,null)::text$q$),
    (20, '⑦ v2_move_class_targets (رصدة ٥٠)', $q$select 'ok '||(r->>'ok')||' · from '||coalesce(r->>'from_section','∅')||' · targets '||jsonb_array_length(r->'targets')||' · excluded '||jsonb_array_length(r->'excluded')||' · blocks '||(r->'blocks')::text||' · show_reason '||(r->>'show_reason_to_new_class')||' · confirm '||(r->>'confirm_word')||' ‖ '||(r->>'privacy_ar')||' ‖ warn '||coalesce(r->>'warning_ar','∅') from (select public.v2_move_class_targets(nullif(current_setting('t.rp'),'')::uuid) r) z$q$),
    (21, '⑦ v2_move_class بلا قرار لجنة', $q$select public.v2_move_class(nullif(current_setting('t.rp'),'')::uuid,coalesce(nullif(current_setting('t.mv'),''),nullif(current_setting('t.po'),''))::uuid,'ب','سبب','أنقل')::text$q$),
    (22, '② إلغاءُ الرصدة ١ وبعدها أربع', $q$select public.v2_record_void(nullif(current_setting('t.r1'),'')::uuid,'رُصدت خطأً','أُلغي')::text$q$),
    (23, '② إلغاءُ الرصدة ٥ بلا سبب', $q$select public.v2_record_void(nullif(current_setting('t.r5'),'')::uuid,' ','أُلغي')::text$q$),
    (24, '② إلغاءُ الرصدة ٥ بلا كلمة الحارس', $q$select public.v2_record_void(nullif(current_setting('t.r5'),'')::uuid,'رُصدت خطأً','الغي')::text$q$),
    (25, '② إلغاءُ الرصدة ٥', $q$select public.v2_record_void(nullif(current_setting('t.r5'),'')::uuid,'رُصدت خطأً','أُلغي')::text$q$),
    (26, '② إلغاؤها ثانيةً', $q$select public.v2_record_void(nullif(current_setting('t.r5'),'')::uuid,'رُصدت خطأً','أُلغي')::text$q$),
    (27, '② بطاقةُ بند ما بعد السلّم بعد الإلغاء', $q$select 'status '||(r->'task'->>'status')||' ‖ settled '||coalesce(r->>'settled_ar','∅') from (select public.v2_task_card(nullif(current_setting('t.bl'),'')::uuid) r) z$q$),
    (28, '③ إقفالُ كلّ بنود الرصدة ١ بالنفي', $q$select count(*)::text||' بندًا' from (select public.v2_task_skip(x::uuid,'فحص') from unnest(string_to_array(nullif(current_setting('t.r1open'),''),',')) x) z$q$),
    (29, '① v2_open_records بعد', $q$select 'count '||(r->>'count')||' (قبل '||current_setting('t.n0')||') · waiting '||(r->>'waiting')||' ‖ '||(r->>'summary_ar')||' ‖ صفّ ٥٠: '||coalesce((select (x->>'student_ar')||' · '||(x->>'problem_ar')||' · '||(x->>'degree_ar')||' · '||(x->>'step_ar')||' · '||(x->>'occurrence_ar')||' · '||(x->>'age_ar')||' · '||(x->>'open_ar')||' · أقدمُ: '||left(x->>'oldest_item_ar',50)||' · عند '||coalesce(x->>'oldest_owner_ar','∅')||' · لجنة '||(x->>'waits_committee')||' · '||coalesce(x->>'why_ar','∅')||' · '||(x->>'state_ar')||' · test '||(x->>'is_test') from jsonb_array_elements(r->'rows') x where x->>'record'=current_setting('t.rp')),'∅')||' ‖ ر١ فيها؟ '||exists(select 1 from jsonb_array_elements(r->'rows') x where x->>'record'=current_setting('t.r1'))||' · ر٥ فيها؟ '||exists(select 1 from jsonb_array_elements(r->'rows') x where x->>'record'=current_setting('t.r5')) from (select public.v2_open_records(current_setting('t.school')::uuid) r) z$q$)
  ) v(n,l,q) order by n loop
    begin execute s.q into r; r := 'نفذ: '||coalesce(r,'—');
    exception when others then r := 'رُفض: '||sqlerrm; end;
    perform set_config('t.s'||s.n, s.l||' ⇐ '||r, true);
  end loop; end $$;
reset role;
do $$ begin
  perform set_config('t.s30','③ حالُ الرصدات في الجدول ⇐ '||(select string_agg('ر'||br.occurrence_no||'('||br.problem_id||'): '||br.status||' → '||v2.record_state_ar(br.status)||coalesce(' · '||br.void_reason,''),' · ' order by br.problem_id, br.occurrence_no) from v2.behavior_records br where br.id::text in (current_setting('t.r1'),current_setting('t.r2'),current_setting('t.r3'),current_setting('t.r4'),current_setting('t.r5'),current_setting('t.rp'))),true);
  perform set_config('t.s31','② إعلامُ وليّ الأمر بالسحب (أحداث restore لهذا الطالب في المعاملة) ⇐ '||coalesce((select string_agg(title_ar||' — '||left(body_ar,90)||' · visible '||visible_to,' ‖ ') from v2.events where student_id::text=current_setting('t.stu') and kind='restore' and created_at >= now() - interval '1 minute'),'لا شيء'),true);
end $$;
select n, current_setting('t.s'||n, true) as result from generate_series(1,31) n;
rollback;
