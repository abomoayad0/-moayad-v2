-- public.v2_meeting_invite(p_meeting uuid, p_kind text, p_person uuid, p_student uuid, p_guardian uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 06d0c03fe6269464bf7b81283072a4ec
CREATE OR REPLACE FUNCTION public.v2_meeting_invite(p_meeting uuid, p_kind text, p_person uuid, p_student uuid, p_guardian uuid, p_note text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare mt record; seat text;
begin
  select * into mt from v2.committee_meetings where id=p_meeting;
  if mt.id is null then raise exception 'الاجتماعُ غيرُ موجود'; end if;
  if mt.status in ('معتمد','ملغًى') then
    raise exception 'لا يُستدعى أحدٌ إلى اجتماعٍ %', mt.status; end if;
  seat := v2.my_seat(mt.school_id,mt.committee_key);
  if seat is distinct from 'chair' then
    raise exception '%', 'استدعاءُ غير الأعضاء لرئيس اللجنة — '||v2.cite_page('committee.meetings')||''; end if;
  if coalesce(p_kind,'منسوب') not in ('منسوب','طالب','وليّ أمر') then
    raise exception 'المستدعى: منسوبٌ أو طالبٌ أو وليُّ أمر'; end if;
  if p_kind='طالب' then perform v2.assert_my_student(p_student,'استدعاء طالب للجنة'); end if;

  insert into v2.meeting_attendance(meeting_id,person_id,guest_kind,
      guest_student_id,guest_guardian_id,invited_as,state,note_ar)
  values (p_meeting, case when coalesce(p_kind,'منسوب')='منسوب' then p_person end,
      coalesce(p_kind,'منسوب'), p_student, p_guardian, 'مستدعى','مدعوّ',
      nullif(btrim(coalesce(p_note,'')),''))
  on conflict do nothing;
  return jsonb_build_object('ok',true,
    'note','يشارك في المناقشة ولا يصوّت على قرارات اللجنة — '||v2.cite_page('committee.meetings')||'');
end $function$
;
