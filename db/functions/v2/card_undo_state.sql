-- v2.card_undo_state(p_event uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 756aec542103822629d7ecf2db1f10dc
CREATE OR REPLACE FUNCTION v2.card_undo_state(p_event uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare e record; me uuid := v2.current_person(); w jsonb;
        v_whole int; v_days int; v_keep int; v_in_period boolean;
begin
  select * into e from v2.card_events where id=p_event;
  if e.id is null then return jsonb_build_object('can_undo',false,'why_ar','لا حدثَ بهذا المعرّف'); end if;
  if e.undone_at is not null then
    return jsonb_build_object('can_undo',false,'why_ar','أُلغي سلفًا'); end if;

  v_keep := v2.rule_n(e.school_id,'card_positive_never_undone');
  if v_keep = 1 and e.polarity = 'positive' then
    return jsonb_build_object('can_undo',false,
      'why_ar','ما مُنح لا يُنزَع — الإيجابيّةُ لا تُسحب (مفتاحٌ في لوحة التحكّم)'); end if;

  if e.person_id <> me and v2.my_role() not in ('principal','deputy','deputy_students','deputy_academic') then
    return jsonb_build_object('can_undo',false,'why_ar','تتراجع عن رصدك أنت'); end if;

  v_whole := v2.rule_n(e.school_id,'card_undo_same_day');
  v_days  := v2.rule_n(e.school_id,'card_undo_task_days');

  if e.kind='practice' and coalesce(e.payload->>'grade_impact','') = 'homework' then
    if current_date - e.on_date > v_days then
      return jsonb_build_object('can_undo',false,
        'why_ar','انقضت مهلةُ '||v2.ar_num(v_days)||' أيّامٍ — راجع الوكيل');
    end if;
    return jsonb_build_object('can_undo',true,'late_submit',true,'why_ar',null,
      'law_ar','المطلوباتُ تُصحَّح خلال '||v2.ar_num(v_days)||' أيّام (رقمٌ في لوحة التحكّم)');
  end if;

  if e.on_date <> current_date then
    return jsonb_build_object('can_undo',false,'why_ar','التراجعُ في يومه — وقد مضى'); end if;

  if v_whole = 1 then
    return jsonb_build_object('can_undo',true,'why_ar',null,
      'law_ar','التراجعُ متاحٌ اليومَ كلَّه (مفتاحٌ في لوحة التحكّم)');
  end if;

  w := v2.card_window(e.school_id, me, current_date);
  v_in_period := coalesce((w->>'can_write')::boolean,false)
                 and coalesce((w->>'period_no')::int,-1) = coalesce(e.period_no,-2);
  if not v_in_period then
    return jsonb_build_object('can_undo',false,
      'why_ar','التراجعُ أثناء الحصّة — وقد انتهت (مفتاحٌ في لوحة التحكّم)');
  end if;
  return jsonb_build_object('can_undo',true,'why_ar',null,
    'law_ar','التراجعُ أثناء الحصّة وحدَها (مفتاحٌ في لوحة التحكّم)');
end $function$
;
