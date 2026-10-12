-- public.v2_card_link_board(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7b40f44340b47842ab1eb48e15fc1a83
CREATE OR REPLACE FUNCTION public.v2_card_link_board(p_school uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid := coalesce(p_school, v2.acting_school()); r jsonb; d int;
begin
  perform v2.assert_my_school(sc,'قراءةَ لوحة ربط البطاقة');
  perform v2.assert_role(array['principal','deputy','deputy_academic','deputy_students',
    'admin_assistant','owner'],'قراءةَ لوحة ربط البطاقة');
  d := v2.rule_n(sc,'card_link_days');

  select coalesce(jsonb_agg(jsonb_build_object(
      'kind',k.kind,'kind_ar', case k.kind
         when 'practice' then 'ممارسة' when 'conduct' then 'مخالفةُ لائحة'
         when 'homework' then 'تكليفُ واجب' when 'role' then 'دورٌ في الفصل'
         when 'exit' then 'خروجٌ من الفصل' when 'report_deputy' then 'إبلاغُ الوكيل'
         else k.kind end,
      'n',k.n,'oldest_days',k.oldest) order by k.n desc),'[]'::jsonb) into r
    from (select ce.kind, count(*)::int n, (current_date - min(ce.on_date))::int oldest
            from v2.card_events ce
           where ce.school_id=sc and ce.linked_at is null and ce.undone_at is null
           group by ce.kind) k;

  return jsonb_build_object('rows',r,
    'total',(select count(*) from v2.card_events ce
       where ce.school_id=sc and ce.linked_at is null and ce.undone_at is null),
    'overdue',(select count(*) from v2.card_events ce
       where ce.school_id=sc and ce.linked_at is null and ce.undone_at is null
         and ce.on_date < current_date - d),
    'limit_days',d,
    'summary_ar','أحداثُ البطاقة التي لم تُرفع إلى المحرّك الرسميّ',
    'note_ar','والبطاقةُ وحدةٌ مستقلّةٌ بقرارٍ مُعلَن — فالربطُ ميدانٌ يُغلق، وما تجاوز '
      ||v2.ar_num(d)||' أيّامٍ يكشفه الجردُ');
end $function$
;
