-- public.v2_my_covers(p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 07520a85ec689dd09fa8d493f08f8190
CREATE OR REPLACE FUNCTION public.v2_my_covers(p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE("الحصّة" smallint, "الفصل" text, "المادة" text, "بدلًا من" text, "لماذا أنا" text, "ما صُنع فيها" text, cover_id uuid)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select c.period_no, coalesce(cs.label_ar,'—'), coalesce(c.subject_ar,'—'),
    coalesce(v2.fn_display_name(pa.full_name),'—'),
    coalesce(c.why_ar,'من احتياطك المعتمد في الجدول'), c.invest_note_ar, c.id
  from v2.period_covers c
  left join v2.class_sections cs on cs.id = c.section_id
  left join v2.people pa on pa.id = c.absent_person
  where c.cover_person = v2.current_person() and c.on_date = p_date and c.voided_at is null
  order by c.period_no
$function$
;
