-- public.v2_day_build(p_school uuid, p_assembly time without time zone, p_period_minutes smallint, p_periods smallint, p_breaks jsonb, p_apply text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5a2efc0a94e4defb36be057dc98582cf
CREATE OR REPLACE FUNCTION public.v2_day_build(p_school uuid, p_assembly time without time zone, p_period_minutes smallint, p_periods smallint, p_breaks jsonb, p_apply text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare t time; i int; b jsonb; plan jsonb := '[]'::jsonb; mins int; lbl text; cutoff time;
  v_asm int; v_dis int; v_brk int; v_pmin int; v_pmax int; v_cut int;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
                         'بناءَ اليوم الدراسيّ');
  if not v2.my_school(p_school) then raise exception '%', v2.not_my_school_ar(); end if;
  if p_assembly is null then raise exception 'اكتب وقتَ الاصطفاف'; end if;
  v_asm  := v2.rule_n(p_school,'assembly_minutes');
  v_dis  := v2.rule_n(p_school,'dismissal_minutes');
  v_brk  := v2.rule_n(p_school,'break_minutes_default');
  v_pmin := v2.rule_n(p_school,'period_minutes_min');
  v_pmax := v2.rule_n(p_school,'periods_per_day_max');
  v_cut  := v2.rule_n(p_school,'late_cutoff_after_period');
  if coalesce(p_period_minutes,0) < v_pmin then raise exception 'مدّةُ الحصّة % دقيقةً فأكثر', v2.ar_num(v_pmin); end if;
  if coalesce(p_periods,0) not between 1 and v_pmax then raise exception 'عددُ الحصص من واحدةٍ إلى %', v2.ar_num(v_pmax); end if;

  t := p_assembly;
  plan := plan || jsonb_build_object('kind','break','sub','اصطفاف','label','الاصطفاف الصباحي',
      'from',v2.time_ar(t),'to',v2.time_ar((t + (v_asm||' minutes')::interval)::time),
      'starts',(t)::text);
  t := (t + (v_asm||' minutes')::interval)::time;

  for i in 1..p_periods loop
    plan := plan || jsonb_build_object('kind','period','no',i,
        'label','الحصة '||v2.ar_num(i),
        'from',v2.time_ar(t),'to',v2.time_ar((t + (p_period_minutes||' minutes')::interval)::time),
        'starts',(t)::text);
    t := (t + (p_period_minutes||' minutes')::interval)::time;
    if i = v_cut then cutoff := t; end if;
    -- فترةٌ بعد هذي الحصّة؟
    for b in select * from jsonb_array_elements(coalesce(p_breaks,'[]'::jsonb)) loop
      if (b->>'after_period')::int = i then
        mins := coalesce((b->>'minutes')::int, v_brk);
        lbl  := coalesce(b->>'label', b->>'kind');
        plan := plan || jsonb_build_object('kind','break','sub',b->>'kind','label',lbl,
            'from',v2.time_ar(t),'to',v2.time_ar((t + (mins||' minutes')::interval)::time),
            'minutes',mins,'after_period',i,'starts',(t)::text);
        t := (t + (mins||' minutes')::interval)::time;
      end if;
    end loop;
  end loop;

  plan := plan || jsonb_build_object('kind','break','sub','انصراف','label','الانصراف',
      'from',v2.time_ar(t),'to',v2.time_ar((t + (v_dis||' minutes')::interval)::time),
      'starts',(t)::text);

  if btrim(coalesce(p_apply,'')) <> 'أقرّ' then
    return jsonb_build_object('ok',true,'applied',false,'plan',plan,
      'ends_ar', v2.time_ar(t),
      'cutoff_ar', v2.time_ar(cutoff),
      'note','هذا مقترحٌ يُعرض ولا يُثبَّت — اكتب «أقرّ» لتثبيته');
  end if;

  -- 🔑 التثبيت
  delete from v2.period_slots where school_id=p_school;
  update v2.break_slots set active=false where school_id=p_school;

  t := (p_assembly + (v_asm||' minutes')::interval)::time;
  insert into v2.break_slots(school_id,kind,label_ar,starts_at,ends_at,needs_duty,note_ar)
  values (p_school,'اصطفاف','الاصطفاف الصباحي',p_assembly,t,true,'بُني من لوحة اليوم');

  for i in 1..p_periods loop
    insert into v2.period_slots(school_id,period_no,label_ar,starts_at,ends_at)
    values (p_school,i,'الحصة '||v2.ar_num(i),t,
        (t + (p_period_minutes||' minutes')::interval)::time);
    t := (t + (p_period_minutes||' minutes')::interval)::time;
    for b in select * from jsonb_array_elements(coalesce(p_breaks,'[]'::jsonb)) loop
      if (b->>'after_period')::int = i then
        mins := coalesce((b->>'minutes')::int, v_brk);
        insert into v2.break_slots(school_id,kind,label_ar,starts_at,ends_at,
            after_period,needs_duty,note_ar)
        values (p_school, b->>'kind', coalesce(b->>'label', b->>'kind'), t,
            (t + (mins||' minutes')::interval)::time, i, true, 'بُني من لوحة اليوم');
        t := (t + (mins||' minutes')::interval)::time;
      end if;
    end loop;
  end loop;

  insert into v2.break_slots(school_id,kind,label_ar,starts_at,ends_at,needs_duty,note_ar)
  values (p_school,'انصراف','الانصراف',t,(t + (v_dis||' minutes')::interval)::time,true,
      'بُني من لوحة اليوم');

  update v2.day_settings set assembly_at=p_assembly,
      period1_at=(p_assembly + (v_asm||' minutes')::interval)::time,
      period_minutes=p_period_minutes,
      late_cutoff_at=coalesce(cutoff, late_cutoff_at),
      late_cutoff_note='نهايةُ الحصة '||v2.ar_num(v_cut)||' — بُني من لوحة اليوم'
   where school_id=p_school;

  return jsonb_build_object('ok',true,'applied',true,'plan',plan,
    'ends_ar', v2.time_ar(t),
    'note','ثُبّت اليومُ — والجدولُ القائمُ لم يُمسّ، فراجع حصصَه');
end $function$
;
