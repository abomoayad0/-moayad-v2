-- public.v2_standby_need_set(p_school uuid, p_need smallint, p_weekday smallint, p_period smallint, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7296401a3174299725c8293afd579953
CREATE OR REPLACE FUNCTION public.v2_standby_need_set(p_school uuid, p_need smallint, p_weekday smallint DEFAULT NULL::smallint, p_period smallint DEFAULT NULL::smallint, p_note text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare maxp smallint; v_max int;
begin
  perform v2.assert_role(array['principal','deputy_academic','deputy','deputy_school'],
                         'ضبط عدد الاحتياط');
  perform v2.assert_my_school(p_school, 'ضبط عدد الاحتياط');

  v_max := (v2.rule_n(p_school,'standby_need_max'))::int;
  if p_need is null then raise exception 'اكتب عددَ معلّمي الاحتياط'; end if;
  if p_need < 0 or p_need > v_max then
    raise exception 'عددُ الاحتياط بين صفرٍ و% — وجاء %',
      v2.ar_count(v_max,'معلّمٍ واحد','معلّمين','معلّمين','معلّمًا'), v2.ar_num(p_need);
  end if;

  select max(period_no) into maxp from v2.period_slots where school_id = p_school;
  if p_period is not null and (maxp is null or p_period < 1 or p_period > maxp) then
    raise exception 'ليست حصّةً في جدول مدرستك: %', v2.ar_num(p_period);
  end if;
  if p_weekday is not null and p_weekday not between 0 and 4 then
    raise exception 'اليوم: الأحدُ (٠) إلى الخميس (٤) — وجاء %', v2.ar_num(p_weekday);
  end if;

  insert into v2.standby_need(school_id,weekday,period_no,need,note_ar,set_by)
  values (p_school,p_weekday,p_period,p_need,nullif(btrim(coalesce(p_note,'')),''),v2.current_person())
  on conflict (school_id, coalesce(weekday,-1), coalesce(period_no,-1))
  do update set need = excluded.need, note_ar = excluded.note_ar,
                set_by = excluded.set_by, set_at = now();

  return 'احتياطُ ' ||
    coalesce((select weekday_ar from v2.timetable where weekday = p_weekday limit 1),'كلّ الأيّام') ||
    ' · ' || coalesce(v2.period_ar(p_period), 'كلّ الحصص') ||
    ' = ' || v2.ar_count(p_need,'معلّمٌ واحد','معلّمان','معلّمين','معلّمًا');
exception
  when not_null_violation or unique_violation or check_violation
    or foreign_key_violation or invalid_datetime_format
    or datetime_field_overflow or invalid_text_representation then
    raise exception '%', v2.say_lock('v2_standby_need_set', sqlstate, sqlerrm);
end $function$
;
