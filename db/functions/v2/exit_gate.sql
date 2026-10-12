-- v2.exit_gate(p_student uuid, p_to_where text, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 43c7a203c48b30cbfa8547de5c7be73d
CREATE OR REPLACE FUNCTION v2.exit_gate(p_student uuid, p_to_where text, p_note text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; yr uuid; grd smallint; sect text; me uuid := v2.current_person();
        w jsonb; b text; v_sec uuid; n int; v_max int;
begin
  if me is null then raise exception 'لا بدّ من تسجيل الدخول'; end if;
  if p_to_where not in ('restroom','counselor','deputy','principal','health','admin','activity','other') then
    raise exception 'المقصد: دورةُ المياه · الموجّه الطلابيّ · وكيلُ شؤون الطلبة · مديرُ المدرسة · الموجّه الصحّيّ · الإدارة · نشاط · أخرى';
  end if;

  select e.school_id, e.year_id, e.grade, e.section into sc, yr, grd, sect
    from v2.enrolments e where e.student_id = p_student and e.status='active' limit 1;
  if sc is null then raise exception 'الطالبُ لا قيدَ فعّالَ له'; end if;
  perform v2.assert_my_school(sc,'تخريجَ الطالب من الفصل');

  b := v2.card_blocked(p_student, current_date);
  if b is not null then raise exception '% — ولا يُخرَّج من حصّةٍ هو غائبٌ عنها', b; end if;

  if p_to_where = 'other' and v2.rule_n(sc,'exit_needs_note_other') = 1
     and btrim(coalesce(p_note,'')) = '' then
    raise exception 'مقصدٌ «أخرى» يلزمه نصٌّ مكتوب — أين ذهب؟';
  end if;

  w := v2.card_window(sc, me, current_date);
  if not coalesce((w->>'can_write')::boolean,false)
     and v2.rule_n(sc,'exit_outside_window') <> 1 then
    raise exception '%', coalesce(w->>'why_ar','انتهى وقتُ التخريج');
  end if;

  select cs.id into v_sec from v2.class_sections cs
   where cs.school_id = sc and cs.grade = grd and cs.section = sect limit 1;

  if exists (select 1 from v2.class_exits x
              where x.student_id = p_student and x.back_at is null) then
    raise exception 'هو خارجٌ الآن ولم تُسجَّل عودتُه — سجِّلها أوّلًا';
  end if;

  if v2.rule_n(sc,'exit_one_at_a_time') = 1 and v_sec is not null
     and exists (select 1 from v2.class_exits x
                  where x.section_id = v_sec and x.on_date = current_date
                    and x.back_at is null) then
    raise exception 'في الفصل طالبٌ خارجٌ الآن — ولا يخرج اثنان معًا (رقمٌ في لوحة التحكّم)';
  end if;

  v_max := (v2.rule_n(sc,'exit_max_per_day_student'))::int;
  select count(*) into n from v2.class_exits x
   where x.student_id = p_student and x.on_date = current_date;
  if n >= v_max then
    raise exception 'خرج اليومَ % مرّاتٍ وهو الحدُّ — وارفعه من لوحة التحكّم إن احتجت',
      v2.ar_num(n);
  end if;

  return jsonb_build_object('school',sc,'year',yr,'me',me,'section',v_sec,
    'term', v2.fn_term_of(sc, current_date),
    'period', (w->>'period_no')::smallint,
    'slot', nullif(w->>'slot',''),
    'is_test', coalesce((select s.test_mode from v2.schools s where s.id=sc),false));
end $function$
;
