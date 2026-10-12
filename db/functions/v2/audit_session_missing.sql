-- v2.audit_session_missing()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 49e7acbe1df3fd183844f1a42182db71
CREATE OR REPLACE FUNCTION v2.audit_session_missing()
 RETURNS TABLE(obj text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select
    'حصّةٌ لم تُفتح · ' || coalesce(cs.label_ar,'فصل') || ' · الحصّة ' || v2.ar_num(t.period_no),
    'مضى وقتُها اليومَ ولم يُفتح لها شيء — فلا يُعرف هل دخل الصفَّ أحد. وصاحبُها: '
      || coalesce(v2.fn_display_name(p.full_name),'—'),
    'خلل'
  from v2.timetable t
  join v2.class_sections cs on cs.id = t.section_id
  join v2.people p on p.id = t.person_id
  join v2.period_slots ps on ps.school_id = t.school_id and ps.period_no = t.period_no
  where t.weekday = extract(dow from current_date)::smallint
    and t.slot_kind in ('teaching','activity')
    and v2.fn_day_kind(t.school_id, current_date) in ('study','exam')
    and ps.ends_at < (now() at time zone 'Asia/Riyadh')::time
    and not exists (select 1 from v2.class_sessions s
                     where s.school_id = t.school_id and s.on_date = current_date
                       and s.period_no = t.period_no and s.section_id = t.section_id);
$function$
;
