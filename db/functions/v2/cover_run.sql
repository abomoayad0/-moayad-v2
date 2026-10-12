-- v2.cover_run(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 341a204b7f36278ea5f38744f64d81af
CREATE OR REPLACE FUNCTION v2.cover_run(p_school uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE(period_no smallint, section_ar text, subject_ar text, absent_ar text, cover_ar text, basis_ar text, note_ar text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare
  ru v2.cover_rules; v_term smallint; v_wd smallint; v_me uuid; n_days int;
  s record; v_pid uuid; v_bas text; v_year uuid;
begin
  perform v2.assert_role(array['principal','deputy_academic','deputy','deputy_school'],
                         'توزيع تغطية حصص الغائب');
  perform v2.assert_my_school(p_school, 'توزيع تغطية حصص الغائب');
  ru := v2.cover_rules_of(p_school);
  if not ru.auto_on then
    raise exception 'التوزيعُ الآليُّ مطفأٌ في إعدادات مدرستك — شغّله من لوحة التحكم، أو وزّع بيدك';
  end if;
  select count(*) into n_days from v2.fn_school_days(p_school, p_date, p_date);
  if n_days = 0 then
    raise exception 'ليس يومَ دراسةٍ في تقويم مدرستك: %', p_date;
  end if;
  v_wd := extract(dow from p_date)::smallint;
  v_term := v2.fn_term_of(p_school, p_date);
  v_me := v2.current_person();

  for s in
    select e.slot, e.period_no pn, e.section_id sid, e.subject_ar subj,
           sa.person_id absent,
           (select t9.year_id from v2.timetable t9 where t9.id = e.slot) yid
      from v2.staff_absences sa
      cross join lateral v2.effective_periods(p_school, sa.person_id, p_date) e
     where sa.school_id = p_school and sa.on_date = p_date and sa.voided_at is null
       and (sa.from_period is null or e.period_no >= sa.from_period)
       and (sa.to_period   is null or e.period_no <= sa.to_period)
       and not exists (
             select 1 from v2.period_covers c
              where c.school_id = p_school and c.on_date = p_date
                and c.period_no = e.period_no
                and c.section_id is not distinct from e.section_id
                and c.voided_at is null)
     order by e.period_no
  loop
    v_pid := null; v_bas := null;
    select x.person_id, x.basis into v_pid, v_bas
      from v2.cover_candidates(p_school, v_wd, s.pn, p_date, s.subj) x
     where x.blocked_ar is null order by x.ord limit 1;

    insert into v2.period_covers(
      school_id, year_id, term_no, on_date, weekday, period_no, section_id, subject_ar,
      absent_person, source_slot, cover_person, cover_basis, decided, decided_by,
      why_ar, gap_reason_ar)
    values (
      p_school, s.yid, v_term, p_date, v_wd, s.pn, s.sid, s.subj,
      s.absent, s.slot, v_pid, coalesce(v_bas,'none'),
      case when v_pid is null then 'gap' else 'auto' end, v_me,
      case when v_pid is not null then
        case when v_bas = 'standby'
          then 'من احتياطه المعتمد في الجدول · الأقلُّ تغطيةً (س-٨-ا-١ سياسة ٠١)'
          else 'فارغٌ في هذا الوقت — بإذن مدرستك عند نفاد الانتظار' end end,
      case when v_pid is null then v2.cover_gap_why(p_school, v_wd, s.pn, p_date) end);

    period_no  := s.pn;
    section_ar := coalesce((select cs.label_ar from v2.class_sections cs where cs.id = s.sid), '—');
    subject_ar := coalesce(s.subj, '—');
    absent_ar  := (select v2.fn_display_name(pe.full_name) from v2.people pe where pe.id = s.absent);
    cover_ar   := coalesce((select v2.fn_display_name(pe2.full_name) from v2.people pe2 where pe2.id = v_pid),
                           '— بلا تغطية');
    basis_ar   := case v_bas when 'standby' then 'احتياطٌ معتمد' when 'free' then 'فارغٌ بإذن المدرسة'
                             else 'لا أحد' end;
    note_ar    := case when v_pid is null
                       then v2.cover_gap_why(p_school, v_wd, s.pn, p_date)
                       else null end;
    return next;
  end loop;
end $function$
;
