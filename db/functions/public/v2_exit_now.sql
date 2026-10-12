-- public.v2_exit_now(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a18d9a7e2f87586e998b023cfa32561c
CREATE OR REPLACE FUNCTION public.v2_exit_now(p_school uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid := coalesce(p_school, v2.acting_school());
begin
  if sc is null then raise exception 'أيُّ مدرسة؟'; end if;
  perform v2.assert_my_school(sc,'قراءةَ من هم خارج الفصول');

  return coalesce((
    select jsonb_agg(jsonb_build_object(
        'exit', x.id,
        'student', x.student_id,
        'student_ar', (select v2.fn_display_name(s.full_name) from v2.students s where s.id=x.student_id),
        'section_ar', (select cs.label_ar from v2.class_sections cs where cs.id=x.section_id),
        'to_ar', x.to_where_ar, 'note_ar', x.note_ar,
        'period', x.period_no,
        'minutes', greatest(0,(extract(epoch from (now() - x.out_at))/60)::int),
        'long', greatest(0,(extract(epoch from (now() - x.out_at))/60)::int)
                 > (v2.rule_n(sc,'card_exit_minutes_warn'))::int,
        'by_ar', (select v2.fn_display_name(p.full_name) from v2.people p where p.id=x.out_by))
      order by x.out_at)
    from v2.class_exits x
    where x.school_id = sc and x.on_date = current_date and x.back_at is null),
    '[]'::jsonb);
end $function$
;
