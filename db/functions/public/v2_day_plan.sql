-- public.v2_day_plan(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 0f938878b8fc24ad2ece4a2c4bb5d7e3
CREATE OR REPLACE FUNCTION public.v2_day_plan(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb; d record; issues jsonb := '[]'::jsonb; prev time; it record; tot int;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select * into d from v2.day_settings where school_id=p_school;
  if d.school_id is null then
    raise exception 'لا توقيتاتِ يومٍ لمدرستك — أسّسها أوّلًا'; end if;

  -- 🔑 الفحوصُ الذكيّة
  if d.late_cutoff_at is not null and d.close_at is not null
     and d.close_at < d.late_cutoff_at then
    issues := issues || jsonb_build_object('kind','close_before_cutoff',
      'text','الإقفالُ ('||v2.time_ar(d.close_at)||') قبل حدّ التأخّر ('||
             v2.time_ar(d.late_cutoff_at)||') — فالحدُّ لا يبلغه أحد');
  end if;

  prev := null;
  for it in
    select starts_at, ends_at, 'period' k, 'الحصة '||v2.ar_num(period_no) lbl
      from v2.period_slots where school_id=p_school
    union all
    select starts_at, ends_at, 'break', label_ar
      from v2.break_slots where school_id=p_school and active and kind<>'انصراف'
    order by 1
  loop
    if prev is not null and it.starts_at > prev then
      issues := issues || jsonb_build_object('kind','gap',
        'text','فراغٌ بلا اسمٍ من '||v2.time_ar(prev)||' إلى '||v2.time_ar(it.starts_at)||
               ' — سمِّه فسحةً أو صلاةً أو احذفه');
    elsif prev is not null and it.starts_at < prev then
      issues := issues || jsonb_build_object('kind','overlap',
        'text','تداخلٌ عند '||v2.time_ar(it.starts_at)||' — '||it.lbl);
    end if;
    prev := it.ends_at;
  end loop;

  if d.late_cutoff_at is null then
    issues := issues || jsonb_build_object('kind','no_cutoff',
      'text','لا حدَّ للتأخّر — فمن وصل آخرَ اليوم يُعدّ متأخّرًا لا غائبًا');
  end if;

  select count(*) into tot from v2.period_slots where school_id=p_school;

  select jsonb_build_object(
    'settings', jsonb_build_object(
      'assembly_ar',v2.time_ar(d.assembly_at),
      'period1_ar',v2.time_ar(d.period1_at),
      'period_minutes',d.period_minutes,
      'period_minutes_ar',v2.ar_num(d.period_minutes),
      'periods_count',tot,'periods_count_ar',v2.ar_num(tot),
      'grace_ar',v2.ar_num(d.late_grace_min),
      'close_ar',v2.time_ar(d.close_at),
      'late_cutoff_ar',v2.time_ar(d.late_cutoff_at),
      'late_cutoff_note',d.late_cutoff_note),
    'line', (select coalesce(jsonb_agg(x order by x->>'starts'),'[]'::jsonb) from (
        select jsonb_build_object('kind','break','sub','اصطفاف','label',b.label_ar,
          'starts',b.starts_at,'from',v2.time_ar(b.starts_at),'to',v2.time_ar(b.ends_at),
          'minutes_ar',v2.ar_num((extract(epoch from (b.ends_at-b.starts_at))/60)::int),
          'id',b.id) x
          from v2.break_slots b where b.school_id=p_school and b.active and b.kind='اصطفاف'
        union all
        select jsonb_build_object('kind','period','label','الحصة '||v2.ar_num(s.period_no),
          'no',s.period_no,'starts',s.starts_at,
          'from',v2.time_ar(s.starts_at),'to',v2.time_ar(s.ends_at),
          'minutes_ar',v2.ar_num((extract(epoch from (s.ends_at-s.starts_at))/60)::int))
          from v2.period_slots s where s.school_id=p_school
        union all
        select jsonb_build_object('kind','break','sub',b.kind,'label',b.label_ar,
          'starts',b.starts_at,'from',v2.time_ar(b.starts_at),'to',v2.time_ar(b.ends_at),
          'minutes_ar',v2.ar_num((extract(epoch from (b.ends_at-b.starts_at))/60)::int),
          'after_period',b.after_period,'id',b.id)
          from v2.break_slots b where b.school_id=p_school and b.active and b.kind<>'اصطفاف'
      ) t),
    'day_length_ar', (select v2.ar_num(((extract(epoch from (max(e)-min(s)))/60)::int))
        from (select min(starts_at) s, max(ends_at) e from v2.period_slots
               where school_id=p_school) z),
    'issues', issues,
    'ok', (jsonb_array_length(issues)=0)
  ) into r;
  return r;
end $function$
;
