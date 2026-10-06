-- public.v2_day_build(p_school uuid, p_assembly time without time zone, p_period_minutes smallint, p_periods smallint, p_breaks jsonb, p_apply text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8fbf6f77a9d8b91a827bde7c0cbc1b1b
CREATE OR REPLACE FUNCTION public.v2_day_build(p_school uuid, p_assembly time without time zone, p_period_minutes smallint, p_periods smallint, p_breaks jsonb, p_apply text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare t time; i int; b jsonb; plan jsonb := '[]'::jsonb; mins int; lbl text; cutoff time;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
                         'بناءَ اليوم الدراسيّ');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if p_assembly is null then raise exception 'اكتب وقتَ الاصطفاف'; end if;
  if coalesce(p_period_minutes,0) < 20 then raise exception 'مدّةُ الحصّة عشرون دقيقةً فأكثر'; end if;
  if coalesce(p_periods,0) not between 1 and 12 then raise exception 'عددُ الحصص من ١ إلى ١٢'; end if;

  t := p_assembly;
  plan := plan || jsonb_build_object('kind','break','sub','اصطفاف','label','الاصطفاف الصباحي',
      'from',v2.time_ar(t),'to',v2.time_ar((t + interval '15 minutes')::time),
      'starts',(t)::text);
  t := (t + interval '15 minutes')::time;

  for i in 1..p_periods loop
    plan := plan || jsonb_build_object('kind','period','no',i,
        'label','الحصة '||v2.ar_num(i),
        'from',v2.time_ar(t),'to',v2.time_ar((t + (p_period_minutes||' minutes')::interval)::time),
        'starts',(t)::text);
    t := (t + (p_period_minutes||' minutes')::interval)::time;
    if i = 3 then cutoff := t; end if;
    -- فترةٌ بعد هذي الحصّة؟
    for b in select * from jsonb_array_elements(coalesce(p_breaks,'[]'::jsonb)) loop
      if (b->>'after_period')::int = i then
        mins := coalesce((b->>'minutes')::int, 20);
        lbl  := coalesce(b->>'label', b->>'kind');
        plan := plan || jsonb_build_object('kind','break','sub',b->>'kind','label',lbl,
            'from',v2.time_ar(t),'to',v2.time_ar((t + (mins||' minutes')::interval)::time),
            'minutes',mins,'after_period',i,'starts',(t)::text);
        t := (t + (mins||' minutes')::interval)::time;
      end if;
    end loop;
  end loop;

  plan := plan || jsonb_build_object('kind','break','sub','انصراف','label','الانصراف',
      'from',v2.time_ar(t),'to',v2.time_ar((t + interval '20 minutes')::time),
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

  t := (p_assembly + interval '15 minutes')::time;
  insert into v2.break_slots(school_id,kind,label_ar,starts_at,ends_at,needs_duty,note_ar)
  values (p_school,'اصطفاف','الاصطفاف الصباحي',p_assembly,t,true,'بُني من لوحة اليوم');

  for i in 1..p_periods loop
    insert into v2.period_slots(school_id,period_no,label_ar,starts_at,ends_at)
    values (p_school,i,'الحصة '||v2.ar_num(i),t,
        (t + (p_period_minutes||' minutes')::interval)::time);
    t := (t + (p_period_minutes||' minutes')::interval)::time;
    for b in select * from jsonb_array_elements(coalesce(p_breaks,'[]'::jsonb)) loop
      if (b->>'after_period')::int = i then
        mins := coalesce((b->>'minutes')::int, 20);
        insert into v2.break_slots(school_id,kind,label_ar,starts_at,ends_at,
            after_period,needs_duty,note_ar)
        values (p_school, b->>'kind', coalesce(b->>'label', b->>'kind'), t,
            (t + (mins||' minutes')::interval)::time, i, true, 'بُني من لوحة اليوم');
        t := (t + (mins||' minutes')::interval)::time;
      end if;
    end loop;
  end loop;

  insert into v2.break_slots(school_id,kind,label_ar,starts_at,ends_at,needs_duty,note_ar)
  values (p_school,'انصراف','الانصراف',t,(t + interval '20 minutes')::time,true,
      'بُني من لوحة اليوم');

  update v2.day_settings set assembly_at=p_assembly,
      period1_at=(p_assembly + interval '15 minutes')::time,
      period_minutes=p_period_minutes,
      late_cutoff_at=coalesce(cutoff, late_cutoff_at),
      late_cutoff_note='نهايةُ الحصة الثالثة — بُني من لوحة اليوم'
   where school_id=p_school;

  return jsonb_build_object('ok',true,'applied',true,'plan',plan,
    'ends_ar', v2.time_ar(t),
    'note','ثُبّت اليومُ — والجدولُ القائمُ لم يُمسّ، فراجع حصصَه');
end $function$
;
