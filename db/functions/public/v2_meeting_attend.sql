-- public.v2_meeting_attend(p_meeting uuid, p_person uuid, p_state text, p_excuse text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a22e8fbd9a94fb33f16dbecf78b302f9
CREATE OR REPLACE FUNCTION public.v2_meeting_attend(p_meeting uuid, p_person uuid, p_state text, p_excuse text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare mt record; seat text; rule jsonb; replied int; voters int;
begin
  select * into mt from v2.committee_meetings where id=p_meeting;
  if mt.id is null then raise exception 'الاجتماعُ غيرُ موجود'; end if;
  if mt.status in ('معتمد','ملغًى') then
    raise exception 'لا يُغيَّر حضورُ اجتماعٍ %', mt.status; end if;
  seat := v2.my_seat(mt.school_id,mt.committee_key);
  if seat not in ('chair','rapporteur') then
    raise exception 'تسجيلُ الحضور للرئيس أو المقرّر'; end if;
  if p_state not in ('حاضر','عن بُعد','غائب','معتذر') then
    raise exception 'الحالُ: حاضرٌ · عن بُعد · غائبٌ · معتذر'; end if;

  rule := v2.committee_rule(mt.school_id, mt.committee_key);
  if p_state='عن بُعد' and not (rule->>'allow_remote')::boolean then
    raise exception 'الردُّ عن بُعدٍ غيرُ مقبولٍ في هذي اللجنة — يُضبط من لوحة التحكّم'; end if;
  if p_state='معتذر' and btrim(coalesce(p_excuse,''))='' then
    raise exception 'لا اعتذارَ بلا عذرٍ مكتوب'; end if;

  update v2.meeting_attendance
     set state=p_state, excuse_ar=nullif(btrim(coalesce(p_excuse,'')),'')
   where meeting_id=p_meeting and person_id=p_person;
  if not found then raise exception 'هذا الشخصُ ليس في قائمة الاجتماع'; end if;

  update v2.committee_meetings set status='منعقد'
   where id=p_meeting and status='مدعوّ إليه';

  select count(*) into replied from v2.meeting_attendance
   where meeting_id=p_meeting and state in ('حاضر','عن بُعد') and can_vote;
  select count(*) into voters from v2.meeting_attendance
   where meeting_id=p_meeting and can_vote;
  return jsonb_build_object('ok',true,'replied',replied,'members',voters,
    'quorum_min', rule->>'quorum_min');
end $function$
;
