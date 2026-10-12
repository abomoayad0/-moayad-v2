-- v2.card_gate(p_student uuid, p_what text, p_needs_window boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 0212efa0395f45125b690c6bc88c964b
CREATE OR REPLACE FUNCTION v2.card_gate(p_student uuid, p_what text, p_needs_window boolean DEFAULT true)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; me uuid := v2.current_person(); w jsonb; b text;
begin
  if me is null then raise exception 'لا بدّ من تسجيل الدخول — ولا تقع كتابةٌ بلا هويّة'; end if;
  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  if sc is null then raise exception 'الطالبُ لا قيدَ فعّالَ له'; end if;
  perform v2.assert_my_school(sc, p_what);

  b := v2.card_blocked(p_student, current_date);
  if b is not null then raise exception '%', b; end if;

  w := v2.card_window(sc, me, current_date);
  if p_needs_window and not (w->>'can_write')::boolean then
    raise exception '%', coalesce(w->>'why_ar','انتهى وقتُ الرصد');
  end if;

  return jsonb_build_object('school',sc,'person',me,'window',w,
    'term', v2.fn_term_of(sc, current_date),
    'year', (select e.year_id from v2.enrolments e
              where e.student_id=p_student and e.status='active' limit 1));
end $function$
;
