-- v2.audit_session_incomplete()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 61d1595469b3e9028720521b23284089
CREATE OR REPLACE FUNCTION v2.audit_session_incomplete()
 RETURNS TABLE(obj text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select
    'حصّةٌ ناقصة · ' || coalesce(cs.label_ar,'فصل') || ' · الحصّة ' || v2.ar_num(s.period_no)
      || ' · ' || s.on_date::text,
    coalesce(s.note_ar,'أُقفلت آليًّا') || ' — وصاحبُها: '
      || coalesce(v2.fn_display_name(p.full_name),'—'),
    'خلل'
  from v2.class_sessions s
  join v2.class_sections cs on cs.id = s.section_id
  join v2.people p on p.id = s.person_id
  where s.auto_closed
    and (s.attendance_at is null or s.lesson_ar is null)
    and s.on_date >= current_date - 30;
$function$
;
