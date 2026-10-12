-- public.v2_my_now_board(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 467b1415eeed621caf74556ef09e417c
CREATE OR REPLACE FUNCTION public.v2_my_now_board(p_school uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; r jsonb;
begin
  sc := coalesce(p_school, v2.acting_school());
  if sc is null then raise exception 'أيُّ مدرسة؟'; end if;
  perform v2.assert_my_school(sc,'قراءة جدولي');
  select coalesce(jsonb_agg(jsonb_build_object(
      'period_no', n.period_no,
      'period_ar', v2.period_ar(n.period_no),
      'starts_at', n.starts_at, 'ends_at', n.ends_at,
      'time_ar', to_char(n.starts_at,'HH24:MI')||' — '||to_char(n.ends_at,'HH24:MI'),
      'section_label', n.section_label, 'section_id', n.section_id,
      'subject_ar', n.subject_ar, 'room_ar', n.room_ar,
      'students_n', n.students_n,
      'students_ar', v2.ar_count0(n.students_n,'لا طالبَ في الكشف',
          'طالبٌ واحد','طالبان','طلّاب','طالبًا'),
      'state', n.state) order by n.period_no), '[]'::jsonb) into r
    from v2.fn_my_now(sc) n;
  return jsonb_build_object('rows', r, 'count', jsonb_array_length(r),
    'summary_ar', case when jsonb_array_length(r) = 0
      then 'لا حصّةَ لك الآن' else null end);
end $function$
;
