-- v2.role_gate(p_section uuid, p_subject text, p_code text, p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 10618efb1f52df5f1047499cd43d18aa
CREATE OR REPLACE FUNCTION v2.role_gate(p_section uuid, p_subject text, p_code text, p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; me uuid := v2.current_person(); grd smallint; sct text;
        r record; n int; v_max int;
begin
  if me is null then raise exception 'لا بدّ من تسجيل الدخول'; end if;
  select cs.school_id, cs.grade, cs.section into sc, grd, sct
    from v2.class_sections cs where cs.id = p_section;
  if sc is null then raise exception 'فصلٌ غيرُ موجود'; end if;
  if not v2.my_school(sc) then raise exception 'ليست مدرستَك'; end if;

  if not v2.work_teaches(me, p_section, p_subject) then
    raise exception 'لا تُدرّس % في هذا الفصل — والدورُ في مادّتك وحدَها', p_subject;
  end if;

  select * into r from v2.class_roles
   where code = p_code and active and (school_id is null or school_id = sc)
   order by school_id nulls last limit 1;
  if r.code is null then raise exception 'دورٌ غيرُ معروف'; end if;

  if not exists (select 1 from v2.enrolments en
                  where en.student_id = p_student and en.school_id = sc
                    and en.grade = grd and en.section = sct and en.ended_on is null) then
    raise exception 'هذا الطالبُ ليس في هذا الفصل';
  end if;

  if exists (select 1 from v2.class_role_holders h
              where h.section_id=p_section and h.subject_ar=p_subject
                and h.role_code=p_code and h.student_id=p_student and h.ended_at is null) then
    raise exception 'هو يحمل هذا الدورَ الآن في مادّتك';
  end if;

  select count(*) into n from v2.class_role_holders h
   where h.section_id=p_section and h.subject_ar=p_subject
     and h.role_code=p_code and h.ended_at is null;
  if n >= r.max_holders then
    raise exception '«%» يحمله % في مادّتك — وهو الحدُّ · اعزِل أحدَهم أو ارفع الحدَّ من لوحة التحكّم',
      r.title_ar, v2.ar_count(n,'واحد','اثنان','طلّاب','طالبًا');
  end if;

  v_max := (v2.rule_n(sc,'role_max_per_student'))::int;
  select count(*) into n from v2.class_role_holders h
   where h.section_id=p_section and h.subject_ar=p_subject
     and h.student_id=p_student and h.ended_at is null;
  if n >= v_max then
    raise exception 'عليه % في مادّتك — وهو أقصى ما تسمح به لوحةُ التحكّم',
      v2.ar_count(n,'دورٌ واحد','دوران','أدوار','دورًا');
  end if;

  return jsonb_build_object('school',sc,'me',me,'role_ar',r.title_ar,
    'term', v2.fn_term_of(sc, current_date),
    'year', (select y.id from v2.academic_years y where y.school_id=sc and y.is_current limit 1),
    'is_test', coalesce((select s.test_mode from v2.schools s where s.id=sc),false));
end $function$
;
