-- public.v2_loyalty_record(p_student uuid, p_source text, p_note text, p_period smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1178c21cf5fa4078d851a41fdcfded3c
CREATE OR REPLACE FUNCTION public.v2_loyalty_record(p_student uuid, p_source text, p_note text DEFAULT NULL::text, p_period smallint DEFAULT NULL::smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare
  sc uuid; me uuid; s v2.loyalty_sources;
  cap int; used int; bal int; yr uuid; tm smallint;
  sect uuid; sess uuid; new_id uuid; role_key text; role_label text;
begin
  me := v2.current_person();
  perform v2.assert_my_student(p_student, 'حركةَ نقاطِ الولاء');
  select school_id into sc from v2.students where id = p_student;

  s := v2.loyalty_source(sc, p_source);
  if s.id is null then
    raise exception 'لا مصدرَ لنقاط الولاء بالرمز «%» — أو أنّه مُغلقٌ في لوحة التحكّم', p_source;
  end if;

  if s.auto_kind = 'engine' then
    raise exception '«%» تُمنح آليًّا ولا تُطلب بيد — %', s.title_ar,
      coalesce(s.auto_note_ar,'محرّكُها يمنحها في موضعها');
  end if;
  if s.auto_kind = 'blocked' then
    raise exception '«%» لا تُمنح — %', s.title_ar,
      coalesce(s.auto_note_ar,'لا محرّكَ لها بعد');
  end if;

  perform v2.assert_role(s.who_may, format('حركةَ «%s»', s.title_ar));

  if s.points > v2.rule_n(sc, 'loyalty_max_per_act') then
    raise exception 'وزنُ «%» (%) يتجاوز أكبرَ ما يُقبل في الحركة الواحدة (%) — يُضبط في لوحة التحكّم',
      s.title_ar, v2.ar_num(s.points), v2.ar_num(v2.rule_n(sc, 'loyalty_max_per_act'));
  end if;

  if (s.needs_note or (s.kind = 'deduct' and v2.rule_n(sc, 'loyalty_deduct_needs_note') = 1))
     and coalesce(btrim(p_note), '') = '' then
    raise exception '«%» لا يُقبل بلا سببٍ مكتوب', s.title_ar;
  end if;

  cap  := coalesce(s.week_cap, v2.rule_n(sc, 'loyalty_week_cap_default'));
  used := v2.loyalty_week_used(sc, p_student, s.code, current_date);
  if used + s.points > cap then
    raise exception 'بلغ «%» سقفَه الأسبوعيَّ على هذا الطالب — المسجَّلُ % من %',
      s.title_ar, v2.ar_num(used), v2.ar_num(cap);
  end if;

  bal := v2.loyalty_balance(sc, p_student);
  if s.kind = 'deduct' and v2.rule_n(sc, 'loyalty_allow_negative') = 0 and bal - s.points < 0 then
    raise exception 'رصيدُه % والخصمُ % — والرصيدُ لا يهبط تحت الصفر بقاعدة المدرسة',
      v2.ar_num(bal), v2.ar_num(s.points);
  end if;

  select id into yr from v2.academic_years where school_id = sc and is_current limit 1;
  tm := v2.fn_term_of(sc, current_date);

  if p_period is not null then
    sect := v2.loyalty_section(sc, p_student);
    if sect is not null then
      sess := v2.session_of(sc, me, current_date, p_period, sect, false);
    end if;
  end if;

  role_key   := v2.my_role();
  role_label := coalesce(v2.role_ar(role_key), 'بلا تكليف');

  insert into v2.loyalty_ledger
    (school_id, year_id, term_no, student_id, kind, source_code, points,
     reason_ar, on_date, period_no, class_session, by_person, by_role_ar)
  values
    (sc, yr, tm, p_student, s.kind, s.code, s.points,
     nullif(btrim(coalesce(p_note, '')), ''), current_date, p_period, sess, me, role_label)
  returning id into new_id;

  bal := v2.loyalty_balance(sc, p_student);
  return jsonb_build_object(
    'id', new_id,
    'kind', s.kind,
    'title_ar', s.title_ar,
    'points', s.points,
    'balance', bal,
    'balance_ar', v2.ar_count(bal, 'نقطةٌ واحدة', 'نقطتان', 'نقاط', 'نقطة'),
    'week_left', cap - (used + s.points),
    'week_left_ar', 'بقي من سقفه هذا الأسبوع '||
        v2.ar_count(cap - (used + s.points),'نقطةٌ واحدة','نقطتان','نقاط','نقطة'),
    'linked_session', sess is not null,
    'said_ar', case when s.kind = 'earn'
                    then format('أُضيفت %s لـ«%s» — ورصيدُه الآن %s',
                         v2.ar_num(s.points), s.title_ar, v2.ar_num(bal))
                    else format('خُصمت %s لـ«%s» — ورصيدُه الآن %s',
                         v2.ar_num(s.points), s.title_ar, v2.ar_num(bal)) end,
    'undo_minutes', v2.rule_n(sc, 'loyalty_undo_minutes'));
end $function$
;
