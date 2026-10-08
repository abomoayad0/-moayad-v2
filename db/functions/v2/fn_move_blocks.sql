-- v2.fn_move_blocks(p_record uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 47c5ded045b3f676af2cfa8d0d241856
CREATE OR REPLACE FUNCTION v2.fn_move_blocks(p_record uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  r record; e record; v_item record; v_vic text; v_exam text;
  v_targets jsonb := '[]'::jsonb; v_excluded jsonb := '[]'::jsonb;
  v_blocks jsonb := '[]'::jsonb; s record; v_now int; v_free int;
begin
  select br.*, cp.text_ar ptext, cp.degree_no dno into r
    from v2.behavior_records br join v2.conduct_problems cp on cp.id = br.problem_id
   where br.id = p_record;
  if r.id is null then
    return jsonb_build_object('ok', false,
      'blocks', jsonb_build_array('الرصدةُ غيرُ موجودة')); end if;

  select en.* into e from v2.enrolments en
   where en.student_id = r.student_id and en.status = 'active' limit 1;
  if e.id is null then
    return jsonb_build_object('ok', false,
      'blocks', jsonb_build_array('لا قيدَ فعّالٌ للطالب')); end if;

  -- 🔒 ① قرارُ اللجنة — نصُّ الدليل: «وفقًا لقرار لجنة التوجيه الطلابيّ»
  select mi.id, mi.decision_ar, mi.recommend_ar, m.held_on into v_item
    from v2.meeting_items mi
    join v2.committee_meetings m on m.id = mi.meeting_id
   where mi.record_id = p_record
     and mi.subject_kind = 'طالب'
     and mi.outcome = 'أُقرّ'
     and m.status = 'معتمد'
     and coalesce(m.quorum_met, false)
   order by m.held_on desc limit 1;
  if v_item.id is null then
    v_blocks := v_blocks || jsonb_build_array(
      'لا قرارَ لجنةٍ معتمدًا لهذي الرصدة — والنقلُ لا يقع إلّا بقرار لجنة التوجيه الطلابيّ '||
      '(اجتماعٌ مُعتمدٌ بنصابٍ · وبندٌ في الطالب حالتُه «أُقرّ»)');
  end if;

  -- 🔒 ② فصلٌ آخرُ في الصفّ
  v_vic := (select en2.section from v2.enrolments en2
             where en2.student_id = r.victim_student_id and en2.status = 'active' limit 1);

  for s in
    select cs.section, cs.label_ar, cs.capacity, cs.room_ar
      from v2.class_sections cs
     where cs.school_id = e.school_id and cs.year_id = e.year_id
       and cs.grade = e.grade and cs.active
     order by cs.section
  loop
    if s.section = e.section then continue; end if;

    select count(*) into v_now from v2.enrolments en3
     where en3.school_id = e.school_id and en3.year_id = e.year_id
       and en3.grade = e.grade and en3.section = s.section and en3.status = 'active';

    -- 🔒 ③ فصلُ المتضرّر يُستثنى
    if v_vic is not null and s.section = v_vic then
      v_excluded := v_excluded || jsonb_build_array(jsonb_build_object(
        'section', s.section, 'label_ar', s.label_ar,
        'why', 'فيه الطالبُ المتضرّرُ من الواقعة — ولا يُنقل إليه'));
      continue;
    end if;

    -- 🔒 ④ السعة
    v_free := case when s.capacity is null then null else s.capacity - v_now end;
    if v_free is not null and v_free <= 0 then
      v_excluded := v_excluded || jsonb_build_array(jsonb_build_object(
        'section', s.section, 'label_ar', s.label_ar,
        'why', 'بلغ سعتَه — '||v2.ar_num(v_now)||' من '||v2.ar_num(s.capacity)));
      continue;
    end if;

    v_targets := v_targets || jsonb_build_array(jsonb_build_object(
      'section', s.section, 'label_ar', s.label_ar, 'room_ar', s.room_ar,
      'now', v_now, 'capacity', s.capacity, 'free', v_free,
      'note_ar', case when s.capacity is null
        then 'لم تُضبط سعةُ هذا الفصل في لوحة التحكّم'
        else 'المتاحُ '||v2.ar_num(v_free) end));
  end loop;

  if jsonb_array_length(v_targets) = 0 then
    if jsonb_array_length(v_excluded) = 0 then
      v_blocks := v_blocks || jsonb_build_array(
        'لا فصلَ آخرَ في هذا الصفّ — فلا محلَّ للنقل');
    else
      v_blocks := v_blocks || jsonb_build_array(
        'كلُّ فصولِ الصفِّ الأخرى مستثناة — فلا محلَّ للنقل');
    end if;
  end if;

  -- ⑤ تحذيرُ الاختبارات — تحذيرٌ لا منع (قرار مفرح ج١)
  select ms.title_ar into v_exam from v2.calendar_milestones ms
   where ms.year_id = e.year_id
     and (ms.kind ilike '%exam%' or ms.title_ar like '%اختبار%')
     and ms.from_g is not null
     and current_date between ms.from_g and coalesce(ms.to_g, ms.from_g)
   limit 1;

  return jsonb_build_object(
    'ok', jsonb_array_length(v_blocks) = 0,
    'student', r.student_id,
    'grade', e.grade, 'grade_ar', v2.grade_ar(e.grade),
    'from_section', e.section,
    'problem_ar', rtrim(btrim(r.ptext),'.'),
    'degree_ar', v2.degree_ar(r.dno),
    'decision', case when v_item.id is null then null else jsonb_build_object(
        'item', v_item.id, 'held_on', v_item.held_on,
        'decision_ar', v_item.decision_ar, 'recommend_ar', v_item.recommend_ar) end,
    'targets', v_targets,
    'excluded', v_excluded,
    'blocks', v_blocks,
    'warning_ar', case when v_exam is not null
      then 'الاختباراتُ قائمةٌ ('||v_exam||') — والنقلُ يُغيّر قاعةَ الطالب وجدولَه. '||
           'والقرارُ للّجنة، والنظامُ يُبصّر ولا يمنع' end,
    'confirm_word', 'أنقل',
    'show_reason_to_new_class', false,
    'privacy_ar', 'يُستقبل في فصله الجديد طالبًا لا ملفًّا — ولا يُعلَن سببُ نقله');
end
$function$
;
