-- public.v2_day_mark(p_student uuid, p_state text, p_date date, p_minutes_late smallint, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 376413c72d9649a570770d8857c8bccc
CREATE OR REPLACE FUNCTION public.v2_day_mark(p_student uuid, p_state text, p_date date DEFAULT CURRENT_DATE, p_minutes_late smallint DEFAULT NULL::smallint, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; tm smallint; v_closed record; v_id uuid;
        msg text; st text; d text; h text; ctx text;
begin
  perform v2.assert_attendance_hand('تسجيل سجلّ اليوم');
  perform v2.assert_my_student(p_student,'تسجيل سجلّ اليوم');
  if p_state not in ('present','absent','late','permitted') then
    raise exception 'الحالُ غيرُ معروف — وهي: حاضر (present) · غائب (absent) · متأخّر (late) · بإذن (permitted)';
  end if;
  if p_date > current_date then
    raise exception 'لا يُرصد يومٌ لم يأتِ بعد';
  end if;

  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' order by e.created_at desc limit 1;

  select * into v_closed from v2.day_closures
   where school_id=sc and on_date=p_date and reopened_at is null;
  if v_closed.id is not null then
    raise exception 'يومُ % مقفَلٌ — ولا يُعدَّل سجلُّه إلّا بإعادة فتحٍ موثّقةٍ بسببٍ مكتوب · '
      'وبابُها v2_reopen_day', v2.fn_to_hijri(p_date)||' هـ';
  end if;

  tm := v2.term_of_strict(sc, p_date);
  if tm is null then
    raise exception 'اليومُ غيرُ معروفٍ في تقويم مدرستك — فلا يُعرف فصلُه الدراسيّ';
  end if;

  v_id := v2.fn_record_attendance(p_student, p_date, p_state, tm,
            p_minutes_late, p_note, v2.current_person());

  update v2.attendance set source='assistant',
      recorded_role = coalesce(v2.role_ar(v2.my_role()),'إدارة المدرسة')
   where id = v_id;

  perform v2.log_action(sc,p_student,'day_mark','سُجّل سجلُّ اليوم','attendance',v_id,
    jsonb_build_object('state',p_state,'on_date',p_date));

  return v2.attendance_result(p_student, p_date);
exception when others then
  get stacked diagnostics st=returned_sqlstate, msg=message_text, d=pg_exception_detail,
    h=pg_exception_hint, ctx=pg_exception_context;
  perform v2.fn_log_error(msg,'v2_day_mark','المواظبة','سجلّ اليوم',
    jsonb_build_object('student',p_student,'state',p_state,'on_date',p_date),
    st,d,h,ctx,'bridge', case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', msg using errcode = st;
end $function$
;
