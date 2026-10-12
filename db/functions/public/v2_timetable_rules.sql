-- public.v2_timetable_rules(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6f92e04b24740727ba3e5635fe4158cd
CREATE OR REPLACE FUNCTION public.v2_timetable_rules(p_school uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select case when not v2.my_school(p_school) then jsonb_build_object('ok',false,'why',v2.not_my_school_ar())
  else jsonb_build_object(
    'ok', true,
    'standby_default_ar', 'معلّمٌ واحدٌ لكلّ حصّةٍ ما لم تطلب المدرسةُ غيرَه',
    'standby_need', coalesce((select jsonb_agg(jsonb_build_object(
         'اليوم', coalesce(n.weekday::text,'كلّها'),
         'الحصّة', coalesce(n.period_no::text,'كلّها'),
         'العدد', n.need, 'البيان', n.note_ar) order by n.weekday nulls first, n.period_no nulls first)
       from v2.standby_need n where n.school_id = p_school), '[]'::jsonb),
    'pairing_default_ar', 'منفصلةٌ مرّةً واحدةً في اليوم ما لم تطلب المدرسةُ غيرَه',
    'pairing', coalesce((select jsonb_agg(jsonb_build_object(
         'المادّة', s.subject_ar,
         'الصفّ', coalesce(s.grade::text,'كلّها'),
         'القاعدة', case s.mode when 'joined' then 'متّصلة' when 'split' then 'منفصلة' else 'مطلقة' end,
         'حتّى في اليوم', s.max_per_day, 'البيان', s.note_ar) order by s.subject_ar)
       from v2.subject_pairing s where s.school_id = p_school), '[]'::jsonb),
    'citation_ar', 'العدلُ في الأسبوعيّ والانتظار منصوصٌ — س-٨-ا-١ سياسة ٠١ ص١٩٨')
  end;
$function$
;
