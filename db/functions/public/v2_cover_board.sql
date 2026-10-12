-- public.v2_cover_board(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a71f88e4bc6b39cd1267f2b4ab168d85
CREATE OR REPLACE FUNCTION public.v2_cover_board(p_school uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE("الحصّة" smallint, "الفصل" text, "المادة" text, "الغائب" text, "المغطّي" text, "الأساس" text, "بأيّ شيء" text, "السبب" text, "ما صُنع فيها" text, cover_id uuid)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select c.period_no, coalesce(cs.label_ar,'—'), coalesce(c.subject_ar,'—'),
    coalesce(v2.fn_display_name(pa.full_name),'—'),
    coalesce(v2.fn_display_name(pc.full_name),'— بلا تغطية'),
    case c.cover_basis when 'standby' then 'احتياطٌ معتمد' when 'free' then 'فارغٌ بإذن المدرسة'
                       when 'manual' then 'بيد الوكيل' else 'لا أحد' end,
    case c.decided when 'auto' then 'آليًّا' when 'manual' then 'بيد الوكيل' else 'لم تُغطَّ' end,
    coalesce(c.gap_reason_ar, c.why_ar), c.invest_note_ar, c.id
  from v2.period_covers c
  left join v2.class_sections cs on cs.id = c.section_id
  left join v2.people pa on pa.id = c.absent_person
  left join v2.people pc on pc.id = c.cover_person
  where c.school_id = p_school and c.on_date = p_date and c.voided_at is null
    and v2.my_school(p_school)
  order by c.period_no, cs.label_ar
$function$
;
