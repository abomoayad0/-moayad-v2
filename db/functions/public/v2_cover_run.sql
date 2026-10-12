-- public.v2_cover_run(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 845b68fbebeec6f960cc2b40d9bb005d
CREATE OR REPLACE FUNCTION public.v2_cover_run(p_school uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE("الحصّة" smallint, "الفصل" text, "المادة" text, "الغائب" text, "المغطّي" text, "الأساس" text, "الملاحظة" text)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select r.period_no, r.section_ar, r.subject_ar, r.absent_ar, r.cover_ar, r.basis_ar, r.note_ar
  from v2.cover_run(p_school, p_date) r
$function$
;
