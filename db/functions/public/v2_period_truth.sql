-- public.v2_period_truth(p_school uuid, p_section uuid, p_period smallint, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 bbd0dda1526cb024930a855b12d17bd4
CREATE OR REPLACE FUNCTION public.v2_period_truth(p_school uuid, p_section uuid, p_period smallint, p_date date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select case when not v2.my_school(p_school)
    then jsonb_build_object('ok',false,'why','ليست مدرستك')
    else coalesce((select jsonb_build_object('ok',true,
        'person', x.person_id, 'person_ar', x.person_ar, 'subject_ar', x.subject_ar,
        'basis', x.basis,
        'basis_ar', case x.basis when 'schedule' then 'من الجدول المعتمد'
                                 when 'swap' then 'تبديلٌ معتمد'
                                 when 'cover' then 'تغطيةُ غياب'
                                 else 'بلا تغطية' end,
        'why_ar', x.why_ar)
      from v2.period_truth(p_school, p_section, p_period, p_date) x),
      jsonb_build_object('ok',true,'person',null,'person_ar','— لا حصّةَ في هذا الوقت',
        'basis','none','basis_ar','لا حصّةَ لهذا الفصل في هذي الحصّة')) end;
$function$
;
