-- public.v2_exit_now(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 81bd14e228832a37831ef3f3615b71f9
CREATE OR REPLACE FUNCTION public.v2_exit_now(p_school uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid := coalesce(p_school, v2.acting_school()); v_warn int;
begin
  if sc is null then raise exception 'أيُّ مدرسة؟'; end if;
  perform v2.assert_my_school(sc,'قراءةَ من هم خارج الفصول');
  v_warn := (v2.rule_n(sc,'card_exit_minutes_warn'))::int;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
        'exit', x.id,
        'student', x.student_id,
        'student_ar', (select v2.fn_display_name(s.full_name) from v2.students s where s.id=x.student_id),
        'section_ar', (select cs.label_ar from v2.class_sections cs where cs.id=x.section_id),
        'to_ar', x.to_where_ar, 'note_ar', x.note_ar,
        'period', x.period_no,
        'minutes', m.mins,
        'minutes_ar', case when m.mins = 0 then 'خرج الآن'
            else 'منذ '||v2.ar_count(m.mins,'دقيقةٍ واحدة','دقيقتين','دقائق','دقيقة') end,
        'long', m.mins > v_warn,
        'long_ar', case when m.mins > v_warn
            then 'أطولُ من '||v2.ar_num(v_warn)||' دقيقة — وهو حدُّ لوحة التحكّم' end,
        'by_ar', (select v2.fn_display_name(p.full_name) from v2.people p where p.id=x.out_by))
      order by x.out_at)
    from v2.class_exits x
    cross join lateral (select greatest(0,(extract(epoch from (now() - x.out_at))/60)::int) as mins) m
    where x.school_id = sc and x.on_date = current_date and x.back_at is null),
    '[]'::jsonb);
end $function$
;
