-- public.v2_work_kinds()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 11ea3d51dbaa0793989f20f0c1805403
CREATE OR REPLACE FUNCTION public.v2_work_kinds()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; v_due int; v_max int; v_def int; v_need int;
begin
  if auth.uid() is null then raise exception 'لا بدّ من تسجيل الدخول'; end if;
  sc := v2.acting_school();
  if sc is not null then
    v_due  := v2.rule_n(sc,'work_due_max_days');
    v_max  := v2.rule_n(sc,'work_max_open_per_section');
    v_def  := v2.rule_n(sc,'work_due_default_days');
    v_need := v2.rule_n(sc,'work_homework_needs_due');
  end if;
  return jsonb_build_object(
    'kinds', coalesce((select jsonb_agg(jsonb_build_object(
        'code', k.code, 'label_ar', k.label_ar, 'note_ar', k.note_ar) order by k.ord)
      from v2.work_kinds k where k.active), '[]'::jsonb),
    'scopes', jsonb_build_array(
      jsonb_build_object('code','class','label_ar','الفصلُ كلُّه'),
      jsonb_build_object('code','student','label_ar','طالبٌ واحد')),
    'rules', case when sc is null then '{}'::jsonb else jsonb_build_object(
      'homework_needs_due', v_need = 1,
      'due_default_days',   v_def,
      'due_max_days',       v_due,
      'max_open_per_section', v_max,
      'shows_default',      v2.rule_n(sc,'work_shows_default') = 1,
      'notify_default',     v2.rule_n(sc,'work_notify_guardian_default') = 1) end,
    'rules_ar', case when sc is null then null else
      concat_ws(' · ',
        case when v_need = 1 then 'الواجبُ يلزمه موعدُ تسليم' else 'الواجبُ بلا موعدٍ يُقبل' end,
        'والموعدُ الافتراضيُّ بعد '||v2.ar_count(v_def,'يومٍ واحد','يومين','أيّام','يومًا'),
        'ولا يُجاوز '||v2.ar_count(v_due,'يومًا واحدًا','يومين','أيّام','يومًا'),
        'ولا يبقى في الفصل أكثرُ من '||v2.ar_count(v_max,'عملٍ واحدٍ قائم','عملين قائمين','أعمالٍ قائمة','عملًا قائمًا')) end,
    'note_ar','الأنواعُ والمدى والقواعدُ وجملتُها كلُّها من القاعدة — فلا يُصاغ لفظٌ في الشاشة');
end $function$
;
