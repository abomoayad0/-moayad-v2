-- public.v2_badge_award(p_student uuid, p_code text, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b2f07ed13a3dd11ef4dd13dfa5a9b129
CREATE OR REPLACE FUNCTION public.v2_badge_award(p_student uuid, p_code text, p_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; yr uuid; me uuid; b v2.loyalty_badges; new_id uuid; old date; lbl text;
begin
  me := v2.current_person();
  perform v2.assert_my_student(p_student, 'منحَ شارة');
  select school_id into sc from v2.students where id = p_student;
  if sc is null then raise exception 'لا طالبَ بهذا المعرّف'; end if;

  b := v2.badge_of(sc, p_code);
  if b.code is null then
    raise exception 'لا شارةَ بالرمز «%» — أو أنّها مُغلقةٌ في لوحة التحكّم', p_code;
  end if;
  if b.rule_kind <> 'manual' then
    raise exception '«%» تُمنح آليًّا ولا تُمنح بيد — %', b.title_ar,
      v2.badge_rule_ar(sc, b);
  end if;
  if coalesce(array_length(b.who_may,1),0) = 0 then
    raise exception '«%» لا يملك منحَها أحدٌ — فحدِّد من يملكها في لوحة التحكّم', b.title_ar;
  end if;
  perform v2.assert_role(b.who_may, format('منحَ «%s»', b.title_ar));

  if coalesce(btrim(coalesce(p_reason,'')),'') = '' then
    raise exception '«%» لا تُمنح بلا سببٍ مكتوب — فالشارةُ تكريمٌ يُقرأ بعد سنين', b.title_ar;
  end if;

  select id into yr from v2.academic_years where school_id = sc and is_current limit 1;

  select w.awarded_on into old from v2.badge_awards w
   where w.student_id = p_student and w.badge_code = b.code
     and w.year_id is not distinct from yr limit 1;
  if old is not null then
    raise exception 'مُنحت له «%» في % من هذا العام — ولا تُمنح مرّتين',
      b.title_ar, v2.fn_to_hijri(old);
  end if;

  lbl := coalesce(v2.role_ar(v2.my_role()), 'بلا تكليف');

  insert into v2.badge_awards
    (school_id, year_id, student_id, badge_code, awarded_on,
     by_person, by_role_ar, reason_ar, auto)
  values (sc, yr, p_student, b.code, current_date, me, lbl, btrim(p_reason), false)
  returning id into new_id;

  return jsonb_build_object(
    'id', new_id,
    'badge_code', b.code,
    'title_ar', b.title_ar,
    'awarded_on', current_date,
    'awarded_on_ar', v2.fn_to_hijri(current_date),
    'by_role_ar', lbl,
    'said_ar', format('مُنح «%s» — %s', b.title_ar, lbl),
    'note_ar', 'والشارةُ لا تُنزَع · ولا تُمنح له مرّةً أخرى في هذا العام');
end $function$
;
