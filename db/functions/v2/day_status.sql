-- v2.day_status(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 0adccec9c7c4f4f43dda2031e9993786
CREATE OR REPLACE FUNCTION v2.day_status(p_school uuid, p_date date)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare d record; v_term smallint; v_next date; v_hol text; v_scope text;
begin
  select s.calendar_scope into v_scope from v2.schools s where s.id = p_school;

  select cd.day_kind, cd.note, cd.holiday_id, cd.weekday_ar, cd.on_h into d
    from v2.calendar_days cd
    join v2.calendar_years y on y.id = cd.year_id
   where y.scope_key = v_scope and cd.on_g = p_date;

  v_term := v2.term_of_strict(p_school, p_date);

  select cd.on_g into v_next
    from v2.calendar_days cd
    join v2.calendar_years y on y.id = cd.year_id
   where y.scope_key = v_scope and cd.on_g >= p_date and cd.day_kind in ('study','exam')
   order by cd.on_g limit 1;

  if d.holiday_id is not null then
    select h.title_ar into v_hol from v2.calendar_holidays h where h.id = d.holiday_id;
  end if;

  return jsonb_build_object(
    'in_calendar', d.day_kind is not null,
    'day_kind', d.day_kind,
    'day_kind_ar', case d.day_kind
       when 'study'   then 'يومُ دراسة'
       when 'exam'    then 'يومُ اختبار'
       when 'weekend' then 'إجازةُ أسبوع'
       when 'holiday' then 'إجازةٌ رسميّة'
       else null end,
    'weekday_ar', d.weekday_ar,
    'on_h', d.on_h,
    'holiday_ar', v_hol,
    'term_no', v_term,
    'teachable', d.day_kind in ('study','exam'),
    'next_study', v_next,
    'next_study_ar', case when v_next is null then null
       else (select cd.weekday_ar from v2.calendar_days cd
              join v2.calendar_years y on y.id=cd.year_id
             where y.scope_key=v_scope and cd.on_g=v_next)||' '||
            coalesce(v2.fn_to_hijri(v_next)||' هـ', v_next::text) end,
    'why_ar', case
       when d.day_kind is null and v_scope is null then
         'لم يُحدَّد مسارُ التقويم لمدرستك — اختره من لوحة التحكّم'
       when d.day_kind is null then
         'هذا اليومُ ليس في تقويم مدرستك («'||v_scope||'») — أسّسه من لوحة التحكّم'
       when d.day_kind in ('study','exam') then null
       when d.day_kind = 'weekend' then
         'اليومُ إجازةُ أسبوعٍ ('||coalesce(d.weekday_ar,'')||')'
       else 'اليومُ إجازةٌ رسميّة'||coalesce(' — '||v_hol,'') end);
end $function$
;
