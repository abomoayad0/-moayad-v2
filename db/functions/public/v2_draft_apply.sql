-- public.v2_draft_apply(p_draft uuid, p_confirm text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 038d732e1bb1574ea75b7163faa9eb4a
CREATE OR REPLACE FUNCTION public.v2_draft_apply(p_draft uuid, p_confirm text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare d record; n int;
begin
  perform v2.assert_role(array['principal','deputy_academic','deputy'],'إقرارَ الجدول');
  select * into d from v2.timetable_drafts where id=p_draft;
  if d.id is null then raise exception 'المقترحُ غيرُ موجود'; end if;
  if not v2.my_school(d.school_id) then raise exception 'ليست مدرستك'; end if;
  if d.state <> 'مقترح' then raise exception 'هذا المقترحُ % سلفًا', d.state; end if;
  -- 🔑 إقرارٌ صريحٌ يكتبه الإنسان — فالجدولُ القائمُ يُستبدل
  if btrim(coalesce(p_confirm,'')) <> 'أقرّ' then
    raise exception 'إقرارُ المقترح يستبدل جدولَ مدرستك كلَّه — اكتب «أقرّ» لتأكيده'; end if;

  delete from v2.timetable where school_id=d.school_id;
  insert into v2.timetable(school_id,year_id,term_no,weekday,weekday_ar,period_no,
      section_id,person_id,subject_ar,slot_kind,is_activity)
  select d.school_id,
     (select e.year_id from v2.enrolments e where e.school_id=d.school_id
       and e.status='active' limit 1),
     coalesce(v2.term_of_strict(d.school_id,current_date),1),
     x.weekday,(array['الأحد','الاثنين','الثلاثاء','الأربعاء','الخميس'])[x.weekday],
     x.period_no,x.section_id,x.person_id,x.subject_ar,x.slot_kind,
     (x.slot_kind='activity')
  from v2.timetable_draft_slots x where x.draft_id=p_draft;
  get diagnostics n = row_count;

  update v2.timetable_drafts set state='مُقَرّ', applied_at=now() where id=p_draft;
  return jsonb_build_object('ok',true,'slots',n,
    'note','أُقرَّ الجدولُ وحلّ محلَّ القائم — والمقترحُ محفوظٌ لا يُمحى');
end $function$
;
