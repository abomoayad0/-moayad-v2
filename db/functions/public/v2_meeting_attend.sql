-- public.v2_meeting_attend(p_meeting uuid, p_person uuid, p_state text, p_excuse text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 202985603d919d4ef49e6b35ad11e1e7
CREATE OR REPLACE FUNCTION public.v2_meeting_attend(p_meeting uuid, p_person uuid, p_state text, p_excuse text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare mt record; seat text;
begin
  select * into mt from v2.committee_meetings where id=p_meeting;
  if mt is null then raise exception 'الاجتماعُ غيرُ موجود'; end if;
  if mt.status in ('معتمد','ملغًى') then
    raise exception 'لا يُغيَّر حضورُ اجتماعٍ %', mt.status;
  end if;
  seat := v2.my_seat(mt.school_id,mt.committee_key);
  if seat not in ('chair','rapporteur') then
    raise exception 'تسجيلُ الحضور للرئيس أو المقرّر';
  end if;
  if p_state not in ('حاضر','غائب','معتذر') then
    raise exception 'الحالُ: حاضرٌ أو غائبٌ أو معتذر';
  end if;
  if p_state='معتذر' and btrim(coalesce(p_excuse,''))='' then
    raise exception 'لا اعتذارَ بلا عذرٍ مكتوب';
  end if;
  update v2.meeting_attendance
     set state=p_state, excuse_ar=nullif(btrim(coalesce(p_excuse,'')),'')
   where meeting_id=p_meeting and person_id=p_person;
  if not found then raise exception 'هذا الشخصُ ليس في قائمة الاجتماع'; end if;
  update v2.committee_meetings set status='منعقد'
   where id=p_meeting and status='مدعوّ إليه';
  return jsonb_build_object('ok',true);
end $function$
;
