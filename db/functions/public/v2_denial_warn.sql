-- public.v2_denial_warn(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5631765335a5e3c1dec800e004ea78c8
CREATE OR REPLACE FUNCTION public.v2_denial_warn(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; yr uuid; v_abs int; v_days int; v_limit int; v_before int;
        v_id uuid; v_old record; nm text;
begin
  perform v2.assert_my_student(p_student, 'إنذارَ وليّ الأمر بقرب حدّ الحرمان');
  perform v2.assert_role(array['principal','deputy','deputy_students','deputy_school',
      'deputy_school_students','admin_assistant','admin_assistant_students'],
      'إنذارَ وليّ الأمر بقرب حدّ الحرمان');

  select e.school_id, e.year_id into sc, yr from v2.enrolments e
   where e.student_id = p_student and e.status = 'active'
   order by e.created_at desc limit 1;
  if sc is null then raise exception 'الطالبُ لا قيدَ فعّالَ له'; end if;
  select v2.fn_display_name(full_name) into nm from v2.students where id = p_student;

  select * into v_old from v2.denial_actions
   where student_id = p_student and year_id = yr and kind = 'warning';
  if v_old.id is not null then
    return jsonb_build_object('id', v_old.id, 'already', true,
      'on_ar', v2.fn_to_hijri(v_old.on_date),
      'said_ar', format('أُنذر وليُّ %s من قبل — في %s · ولا يُنذَر مرّتين في السنة',
        coalesce(nm,'الطالب'), v2.fn_to_hijri(v_old.on_date)));
  end if;

  select "أيام_دراسة_مقررة", "غياب_بلا_عذر" into v_days, v_abs
    from v2.fn_register_attendance(sc, yr, null, null, null, null, p_student) limit 1;
  v_limit  := v2.denial_limit(v_days);
  select value_num::int into v_before from v2.conduct_rules where key = 'denial.warn_before_days';
  v_before := coalesce(v_before, 3);

  if v_limit is null then
    raise exception 'لا أيّامَ دراسةٍ مقرَّرةٌ محسوبةٌ لهذه السنة — فلا حدَّ يُقاس عليه';
  end if;
  if coalesce(v_abs,0) < v_limit - v_before then
    raise exception 'غيابُه بغير عذرٍ % والحدُّ % من أصل % — ولا يُنذَر وليُّه قبل أن يبلغ %، وهي مهلةُ الإنذار في قواعد السلوك',
      v2.ar_num(coalesce(v_abs,0)), v2.ar_num(v_limit), v2.ar_num(v_days),
      v2.ar_num(v_limit - v_before);
  end if;

  v_id := v2.fn_denial_warn(p_student);
  if v_id is null then
    raise exception 'لم يُسجَّل الإنذار — والمحرّكُ قيّد سببَه في سجلّ الأخطاء';
  end if;

  return jsonb_build_object('id', v_id, 'already', false,
    'days_absent', v_abs, 'limit_days', v_limit, 'year_days', v_days,
    'said_ar', format('أُنذر وليُّ %s — غيابُه بغير عذرٍ %s والحدُّ %s يومًا من أصل %s · ووصلته الرسالةُ في سجلّ الأحداث',
      coalesce(nm,'الطالب'), v2.ar_num(coalesce(v_abs,0)), v2.ar_num(v_limit), v2.ar_num(v_days)));
end $function$
;
