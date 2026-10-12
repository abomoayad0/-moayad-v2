-- public.v2_standby_need_set(p_school uuid, p_need smallint, p_weekday smallint, p_period smallint, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 148d7c7f5a5f66fa4750a755f8cf7608
CREATE OR REPLACE FUNCTION public.v2_standby_need_set(p_school uuid, p_need smallint, p_weekday smallint DEFAULT NULL::smallint, p_period smallint DEFAULT NULL::smallint, p_note text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare maxp smallint;
begin
  perform v2.assert_role(array['principal','deputy_academic','deputy','deputy_school'],
                         'ضبط عدد الاحتياط');
  perform v2.assert_my_school(p_school, 'ضبط عدد الاحتياط');
  select max(period_no) into maxp from v2.period_slots where school_id = p_school;
  if p_period is not null and (maxp is null or p_period < 1 or p_period > maxp) then
    raise exception 'ليست حصّةً في جدول مدرستك: %', p_period;
  end if;
  insert into v2.standby_need(school_id,weekday,period_no,need,note_ar,set_by)
  values (p_school,p_weekday,p_period,p_need,nullif(btrim(coalesce(p_note,'')),''),v2.current_person())
  on conflict (school_id, coalesce(weekday,-1), coalesce(period_no,-1))
  do update set need = excluded.need, note_ar = excluded.note_ar,
                set_by = excluded.set_by, set_at = now();
  return 'احتياطُ ' ||
    coalesce((select weekday_ar from v2.timetable where weekday = p_weekday limit 1),'كلّ الأيّام') ||
    ' · ' || coalesce('الحصّة ' || v2.ar_num(p_period), 'كلّ الحصص') ||
    ' = ' || v2.ar_count(p_need,'معلّم','معلّمان','معلّمين','معلّمًا');
end $function$
;
