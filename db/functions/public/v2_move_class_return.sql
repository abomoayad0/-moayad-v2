-- public.v2_move_class_return(p_move uuid, p_reason text, p_confirm text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a7122d61a01622b458a2ac176e3534b2
CREATE OR REPLACE FUNCTION public.v2_move_class_return(p_move uuid, p_reason text, p_confirm text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare mv record; e record; v_item record;
begin
  perform v2.assert_role(array['deputy_students','deputy','principal'],
    'إعادةَ الطالب إلى فصله');

  select * into mv from v2.class_moves where id = p_move;
  if mv.id is null then raise exception 'النقلُ غيرُ موجود'; end if;
  perform v2.assert_my_student(mv.student_id, 'إعادة الطالب إلى فصله');
  if mv.returned_at is not null then raise exception 'أُعيد الطالبُ سلفًا'; end if;
  if btrim(coalesce(p_reason,'')) = '' then
    raise exception 'اكتب سببَ الإعادة — فهو قرارٌ يُقيَّد كما قُيّد النقل'; end if;
  if coalesce(p_confirm,'') <> 'أُعيد' then
    raise exception 'اكتب «أُعيد» لتُقرّ إعادةَ الطالب إلى فصله'; end if;

  -- بقرار اللجنة نفسِها — بندٌ معتمدٌ بعد تاريخ النقل
  select mi.id, m.held_on into v_item
    from v2.meeting_items mi
    join v2.committee_meetings m on m.id = mi.meeting_id
   where mi.student_id = mv.student_id
     and mi.subject_kind = 'طالب'
     and mi.outcome = 'أُقرّ'
     and m.status = 'معتمد'
     and coalesce(m.quorum_met,false)
     and m.held_on >= mv.moved_at::date
   order by m.held_on desc limit 1;
  if v_item.id is null then
    raise exception 'لا قرارَ لجنةٍ معتمدًا بعد تاريخ النقل — والإعادةُ بقرار اللجنة نفسِها';
  end if;

  select * into e from v2.enrolments en
   where en.student_id = mv.student_id and en.status = 'active' limit 1;
  if e.section <> mv.to_section then
    raise exception 'الطالبُ ليس في الفصل الذي نُقل إليه — فصلُه الآن «%»', e.section; end if;

  update v2.enrolments set section = mv.from_section where id = e.id;

  update v2.class_moves set returned_at = now(), returned_by = v2.current_person(),
      return_reason_ar = btrim(p_reason), return_item = v_item.id
   where id = p_move;

  insert into v2.events(school_id, kind, on_date, student_id, title_ar, body_ar,
      ref_table, ref_id, visible_to, is_test)
  values (mv.school_id, 'other', current_date, mv.student_id,
      'أُعيد ابنكم إلى فصله',
      'أُعيد إلى '||v2.grade_ar(mv.grade)||' — '||mv.from_section||
      ' بقرار لجنة التوجيه الطلابيّ',
      'class_moves', p_move, 'all', mv.is_test);

  perform v2.log_action(mv.school_id, mv.student_id, 'move_class_return',
    'أُعيد الطالبُ إلى فصله', 'class_moves', p_move,
    jsonb_build_object('from', mv.to_section, 'to', mv.from_section));

  return jsonb_build_object('ok', true, 'move', p_move,
    'headline', 'أُعيد الطالبُ إلى '||mv.from_section||' بقرار اللجنة — وأُشعر وليُّ أمره',
    'note_ar', 'ويبقى النقلُ والرجوعُ في سجلّه — فالنقلُ تربيةٌ لا عقوبةٌ أبديّة');
end
$function$
;
