-- public.v2_meeting_item(p_meeting uuid, p_kind text, p_title text, p_student uuid, p_record uuid, p_opp uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 fcc41ecac6dd32e5cbdddbc57c75176e
CREATE OR REPLACE FUNCTION public.v2_meeting_item(p_meeting uuid, p_kind text, p_title text, p_student uuid, p_record uuid, p_opp uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare mt record; seat text; o smallint; nid uuid; sc uuid;
begin
  select * into mt from v2.committee_meetings where id=p_meeting;
  if mt.id is null then raise exception 'الاجتماعُ غيرُ موجود'; end if;
  if mt.status in ('معتمد','ملغًى') then
    raise exception 'لا يُضاف بندٌ إلى اجتماعٍ %', mt.status; end if;
  seat := v2.my_seat(mt.school_id,mt.committee_key);
  if seat not in ('chair','rapporteur') then
    raise exception 'إضافةُ البنود للرئيس أو المقرّر — ص١٩'; end if;
  if btrim(coalesce(p_title,''))='' then raise exception 'لا بندَ بلا عنوان'; end if;

  -- 🔑 الطالبُ من مدرسة الاجتماع وحدَها
  if p_student is not null then
    select e.school_id into sc from v2.enrolments e
     where e.student_id=p_student and e.status='active' limit 1;
    if sc is distinct from mt.school_id then
      raise exception 'هذا الطالبُ ليس من مدرسة هذي اللجنة'; end if;
  end if;

  select coalesce(max(ord),0)+1 into o from v2.meeting_items where meeting_id=p_meeting;
  insert into v2.meeting_items(meeting_id,ord,subject_kind,title_ar,student_id,record_id,opp_ref)
  values (p_meeting,o,coalesce(p_kind,'طالب'),btrim(p_title),p_student,p_record,p_opp)
  returning id into nid;
  return jsonb_build_object('ok',true,'item',nid,'id',nid,'ord',o);
end $function$
;
