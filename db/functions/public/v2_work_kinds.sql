-- public.v2_work_kinds()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ef6d315ac14783afd3b28e2c63d396ae
CREATE OR REPLACE FUNCTION public.v2_work_kinds()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid;
begin
  if auth.uid() is null then raise exception 'لا بدّ من تسجيل الدخول'; end if;
  sc := v2.acting_school();
  return jsonb_build_object(
    'kinds', coalesce((select jsonb_agg(jsonb_build_object(
        'code', k.code, 'label_ar', k.label_ar, 'note_ar', k.note_ar) order by k.ord)
      from v2.work_kinds k where k.active), '[]'::jsonb),
    'scopes', jsonb_build_array(
      jsonb_build_object('code','class','label_ar','الفصلُ كلُّه'),
      jsonb_build_object('code','student','label_ar','طالبٌ واحد')),
    'rules', case when sc is null then '{}'::jsonb else jsonb_build_object(
      'homework_needs_due', v2.rule_n(sc,'work_homework_needs_due') = 1,
      'due_default_days',   v2.rule_n(sc,'work_due_default_days'),
      'due_max_days',       v2.rule_n(sc,'work_due_max_days'),
      'max_open_per_section', v2.rule_n(sc,'work_max_open_per_section'),
      'shows_default',      v2.rule_n(sc,'work_shows_default') = 1,
      'notify_default',     v2.rule_n(sc,'work_notify_guardian_default') = 1) end,
    'note_ar','الأنواعُ والمدى من فهرسٍ في القاعدة — فلا تُكتب في الشاشة');
end $function$
;
