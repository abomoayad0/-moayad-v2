-- v2.card_window(p_school uuid, p_person uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 dbe5fd81e5f1f973d38bdab71afbf55e
CREATE OR REPLACE FUNCTION v2.card_window(p_school uuid, p_person uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_now time := (now() at time zone 'Asia/Riyadh')::time;
        v_grace int := v2.rule_n(p_school,'card_grace_minutes');
        v_kind text; cur record; nxt record; n_today int;
begin
  v_kind := v2.fn_day_kind(p_school, p_date);
  if v_kind is null or v_kind not in ('study','exam') then
    return jsonb_build_object('can_write',false,
      'why_ar','اليومُ ليس يومَ دراسة — والبطاقةُ للاطّلاع والمتابعة والتكليف',
      'day_kind',v_kind,'now',to_char(v_now,'HH24:MI'));
  end if;

  -- حصصُه اليومَ من طبقة الحقيقة (تُرى التبديلاتُ والتغطيات)
  select count(*) into n_today
    from v2.effective_periods(p_school, p_person, p_date);

  select e.period_no, ps.starts_at, ps.ends_at, e.section_id, e.subject_ar, e.slot
    into cur
    from v2.effective_periods(p_school, p_person, p_date) e
    join v2.period_slots ps on ps.school_id=p_school and ps.period_no=e.period_no
   where v_now >= ps.starts_at
     and v_now <= (ps.ends_at + (v_grace||' minutes')::interval)
   order by ps.starts_at limit 1;

  if cur.period_no is not null then
    return jsonb_build_object('can_write',true,'why_ar',null,
      'period_no',cur.period_no,'section_id',cur.section_id,'slot',cur.slot,
      'subject_ar',cur.subject_ar,'day_kind',v_kind,
      'opens',to_char(cur.starts_at,'HH24:MI'),
      'closes',to_char((cur.ends_at + (v_grace||' minutes')::interval),'HH24:MI'),
      'grace_min',v_grace,'now',to_char(v_now,'HH24:MI'));
  end if;

  if n_today = 0 then
    return jsonb_build_object('can_write',false,'day_kind',v_kind,
      'why_ar','لا حصصَ لك اليومَ — والبطاقةُ للاطّلاع والمتابعة والتكليف',
      'now',to_char(v_now,'HH24:MI'));
  end if;

  select e.period_no, ps.starts_at into nxt
    from v2.effective_periods(p_school, p_person, p_date) e
    join v2.period_slots ps on ps.school_id=p_school and ps.period_no=e.period_no
   where ps.starts_at > v_now order by ps.starts_at limit 1;

  if nxt.period_no is null then
    return jsonb_build_object('can_write',false,'day_kind',v_kind,
      'why_ar','انتهت حصصُك اليومَ — والبطاقةُ للاطّلاع والمتابعة والتكليف',
      'now',to_char(v_now,'HH24:MI'));
  end if;

  return jsonb_build_object('can_write',false,'day_kind',v_kind,
    'next_period',nxt.period_no,'next_at',to_char(nxt.starts_at,'HH24:MI'),
    'why_ar','حصّتُك القادمةُ '||v2.ar_num(nxt.period_no)||' — '||to_char(nxt.starts_at,'HH24:MI')
      ||' · والبطاقةُ للاطّلاع والمتابعة والتكليف',
    'now',to_char(v_now,'HH24:MI'));
end $function$
;
