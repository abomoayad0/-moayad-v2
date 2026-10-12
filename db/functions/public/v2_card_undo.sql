-- public.v2_card_undo(p_event uuid, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 29a28df4fd2f37f552f5dd675f80358e
CREATE OR REPLACE FUNCTION public.v2_card_undo(p_event uuid, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare st jsonb; e record; me uuid := v2.current_person();
        v_pulled boolean := false; v_closed int := 0; v_left int;
begin
  select * into e from v2.card_events where id=p_event;
  if e.id is null then raise exception 'لا حدثَ بهذا المعرّف'; end if;
  perform v2.assert_my_school(e.school_id,'التراجعَ عن حدثٍ في البطاقة');
  if btrim(coalesce(p_reason,''))='' then raise exception 'لا يُلغى رصدٌ بلا سببٍ مكتوب'; end if;

  st := v2.card_undo_state(p_event);
  if not (st->>'can_undo')::boolean then raise exception '%', st->>'why_ar'; end if;

  if e.linked_target = 'practice_records' and e.linked_id is not null then
    if exists (select 1 from v2.practice_records r
                where r.id = e.linked_id and r.escalated_record is not null) then
      raise exception 'صُعِّدت هذي الممارسةُ إلى الدليل — فلا تُسحب من البطاقة، والتصحيحُ عند الوكيل';
    end if;
    perform v2.fn_undo_practice(e.linked_id, btrim(p_reason));
    v_pulled := true;
  end if;

  update v2.card_events
     set undone_at=now(), undone_by=me, undo_reason=btrim(p_reason)
   where id=p_event;

  -- خطوةٌ سُحب سببُها تُسقَط آليًّا، إن لم يبقَ للممارسة رصدٌ قائمٌ يبلغ حدَّها
  if e.kind='practice' and e.code is not null then
    select count(*) into v_left
      from v2.card_events ce
      join v2.class_practices cp on cp.code = ce.code
     where ce.student_id = e.student_id and ce.kind='practice' and ce.code = e.code
       and ce.undone_at is null
       and (cp.threshold_days is null or ce.on_date >= current_date - cp.threshold_days);

    update v2.card_due_steps ds
       set answered_at = now(), answered_by = me,
           answer_note = 'أُسقطت آليًّا — سُحب سببُها من سجلّ الممارسات'
     where ds.student_id = e.student_id and ds.code = e.code
       and ds.kind = 'practice_threshold' and ds.answered_at is null
       and v_left < ds.threshold_n;
    v_closed := case when found then 1 else 0 end;
  end if;

  return jsonb_build_object('ok',true,'event',p_event,'pulled_from_engine',v_pulled,
    'steps_closed', v_closed,
    'summary_ar','أُلغي — «'||e.title_ar||'»'||
      case when v_pulled then ' · وسُحب من سجلّ الممارسات ومعه نقاطُه' else '' end||
      case when v_closed > 0 then ' · وأُسقطت الخطوةُ التي وُلّدت منه' else '' end,
    'law_ar', st->>'law_ar');
end $function$
;
