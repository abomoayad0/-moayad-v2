-- public.v2_my_sessions(p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 0340401c5511c52f1e2344059b99b63d
CREATE OR REPLACE FUNCTION public.v2_my_sessions(p_date date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid := v2.acting_school(); me uuid := v2.current_person();
begin
  if me is null then raise exception 'لا بدّ من تسجيل الدخول'; end if;
  perform v2.session_autoclose(sc);

  return coalesce((
    select jsonb_agg(jsonb_build_object(
        'period', ep.period_no,
        'period_ar', v2.period_ar(ep.period_no),
        'section', ep.section_id,
        'section_ar', (select cs.label_ar from v2.class_sections cs where cs.id=ep.section_id),
        'subject', ep.subject_ar,
        'basis_ar', case ep.basis when 'swap' then 'بتبديلٍ من '||coalesce(ep.from_ar,'زميل')
                                  when 'cover' then 'تغطيةً عن '||coalesce(ep.from_ar,'زميل')
                                  else 'أصالةً' end,
        'at', to_char(ps.starts_at,'HH24:MI')||' – '||to_char(ps.ends_at,'HH24:MI'),
        'at_ar', v2.time_ar(ps.starts_at)||' — '||v2.time_ar(ps.ends_at),
        'session', s.id,
        'opened', s.id is not null,
        'late_min', s.late_min,
        'late_ar', case when s.id is null then null
                        when coalesce(s.late_min,0) = 0 then 'فُتحت في وقتها'
                        else 'فُتحت متأخّرةً '||
                             v2.ar_count(s.late_min,'دقيقةً واحدة','دقيقتين','دقائق','دقيقة') end,
        'attendance_done', s.attendance_at is not null,
        'lesson_ar', s.lesson_ar,
        'closed', s.closed_at is not null,
        'auto_closed', coalesce(s.auto_closed,false),
        'note_ar', s.note_ar,
        'state_ar', case
          when s.id is null then 'لم تُفتح'
          when s.closed_at is not null and s.auto_closed
               and (s.attendance_at is null or s.lesson_ar is null)
            then 'أُقفلت آليًّا وفيها نقص'
          when s.closed_at is not null then 'أُقفلت'
          when s.attendance_at is null then 'مفتوحةٌ — ينقصها اعتمادُ الحضور'
          when s.lesson_ar is null then 'مفتوحةٌ — ينقصها الدرس'
          else 'مفتوحةٌ وجاهزةٌ للإقفال' end)
      order by ep.period_no)
    from v2.effective_periods(sc, me, p_date) ep
    left join v2.period_slots ps on ps.school_id=sc and ps.period_no=ep.period_no
    left join v2.class_sessions s on s.school_id=sc and s.on_date=p_date
         and s.period_no=ep.period_no and s.section_id=ep.section_id), '[]'::jsonb);
end $function$
;
