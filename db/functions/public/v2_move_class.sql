-- public.v2_move_class(p_record uuid, p_task uuid, p_to_section text, p_reason text, p_confirm text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1e4b36ca763e8c50aef809f17ebd1c9b
CREATE OR REPLACE FUNCTION public.v2_move_class(p_record uuid, p_task uuid, p_to_section text, p_reason text, p_confirm text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  b jsonb; t record; r record; e record; v_mv uuid; v_ok boolean := false;
  v_item uuid; x jsonb; st text; m text; d text; h text; c text;
begin
  perform v2.assert_role(array['deputy_students','deputy','principal'],
    'نقلَ الطالب إلى فصلٍ آخر');

  select br.*, cp.text_ar ptext into r
    from v2.behavior_records br join v2.conduct_problems cp on cp.id = br.problem_id
   where br.id = p_record;
  if r.id is null then raise exception 'الرصدةُ غيرُ موجودة'; end if;
  perform v2.assert_my_student(r.student_id, 'نقل الطالب');

  select * into t from v2.behavior_tasks where id = p_task;
  if t.id is null then raise exception 'المهمّةُ غيرُ موجودة'; end if;
  if t.record_id <> p_record then raise exception 'المهمّةُ ليست من هذي الرصدة'; end if;
  if t.kind <> 'move_class' then raise exception 'هذي ليست مهمّةَ نقلِ فصل'; end if;
  if t.status = 'done' then raise exception 'نُفّذ النقلُ سلفًا'; end if;
  if t.status = 'skipped' then
    raise exception 'هذي المهمّةُ متخطّاةٌ — %', coalesce(t.skip_reason,''); end if;

  if btrim(coalesce(p_reason,'')) = '' then
    raise exception 'اكتب سببَ النقل — فهو قرارٌ يُقيَّد في سجلّ الطالب'; end if;

  b := v2.fn_move_blocks(p_record);
  if not (b->>'ok')::boolean then
    raise exception '%', (select string_agg(y::text, ' · ')
      from jsonb_array_elements_text(b->'blocks') y);
  end if;

  -- الوجهةُ من المتاح وحدَه
  for x in select jsonb_array_elements(b->'targets') loop
    if x->>'section' = p_to_section then v_ok := true; end if;
  end loop;
  if not v_ok then
    raise exception 'الفصلُ «%» ليس من الفصول المتاحة. والمتاحُ: %',
      p_to_section,
      coalesce((select string_agg(y->>'section', ' · ')
                from jsonb_array_elements(b->'targets') y), 'لا شيء');
  end if;

  if coalesce(p_confirm,'') <> (b->>'confirm_word') then
    raise exception 'النقلُ قرارٌ يمسّ يومَ الطالب كلَّه — فاكتب «%» لتُقرّه', b->>'confirm_word'; end if;

  v_item := (b#>>'{decision,item}')::uuid;

  select * into e from v2.enrolments en
   where en.student_id = r.student_id and en.status = 'active' limit 1;

  -- ⑥ الأثرُ حقيقيٌّ لا تأشير
  insert into v2.class_moves(school_id, year_id, student_id, record_id, task_id,
      grade, from_section, to_section, meeting_item, reason_ar, moved_by, is_test)
  values (e.school_id, e.year_id, r.student_id, p_record, p_task,
      e.grade, e.section, p_to_section, v_item, btrim(p_reason), v2.current_person(),
      coalesce((select test_mode from v2.schools where id = e.school_id), false))
  returning id into v_mv;

  update v2.enrolments set section = p_to_section where id = e.id;

  -- ⑤ إشعارُ وليّ الأمر — ولا يُقفل البندُ قبل أن يقع
  insert into v2.events(school_id, kind, on_date, student_id, title_ar, body_ar,
      ref_table, ref_id, visible_to, is_test)
  values (e.school_id, 'other', current_date, r.student_id,
      'نُقل ابنكم إلى فصلٍ آخر',
      'نُقل إلى '||v2.grade_ar(e.grade)||' — '||p_to_section||
      ' بقرار لجنة التوجيه الطلابيّ · وبدايةُ دوامه فيه من '||
      coalesce(v2.fn_to_hijri(current_date)||' هـ', current_date::text),
      'class_moves', v_mv, 'all',
      coalesce((select test_mode from v2.schools where id = e.school_id), false));

  update v2.behavior_tasks set status = 'done', done_at = now(),
      done_by = v2.current_person(), ev_on = current_date,
      ev_text = 'نُقل من '||e.section||' إلى '||p_to_section||' — '||btrim(p_reason),
      ev_ref = v_mv::text
   where id = p_task;

  perform v2.log_action(e.school_id, r.student_id, 'move_class',
    'نُقل الطالبُ إلى فصلٍ آخر', 'class_moves', v_mv,
    jsonb_build_object('from', e.section, 'to', p_to_section, 'item', v_item));

  return jsonb_build_object('ok', true, 'move', v_mv,
    'from', e.section, 'to', p_to_section,
    'headline', 'نُقل الطالبُ من '||e.section||' إلى '||p_to_section||
                ' بقرار لجنة التوجيه — وأُشعر وليُّ أمره',
    'warning_ar', b->>'warning_ar',
    'privacy_ar', b->>'privacy_ar',
    'return_ar', 'وله أن يعود إلى فصله بقرار اللجنة نفسِها وبسببٍ مكتوب');
exception when others then
  get stacked diagnostics st=returned_sqlstate, m=message_text, d=pg_exception_detail,
    h=pg_exception_hint, c=pg_exception_context;
  perform v2.fn_log_error(m,'v2_move_class','السلوك','نقل الطالب إلى فصل آخر',
    jsonb_build_object('record',p_record,'task',p_task,'to',p_to_section),
    st,d,h,c,'bridge', case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', m using errcode = st;
end
$function$
;
