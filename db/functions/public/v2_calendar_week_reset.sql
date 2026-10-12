-- public.v2_calendar_week_reset(p_school uuid, p_term smallint, p_week smallint, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d4922198f63c3b66578c274803741782
CREATE OR REPLACE FUNCTION public.v2_calendar_week_reset(p_school uuid, p_term smallint, p_week smallint, p_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_n int;
begin
  perform v2.assert_my_school(p_school,'إعادةَ أسبوعٍ إلى أصله');
  perform v2.assert_role(array['principal','deputy','deputy_school','deputy_academic',
    'deputy_school_students','admin_assistant','admin_assistant_students','info_registrar'],
    'إعادةَ أسبوعٍ إلى أصله');

  update v2.calendar_week_overrides o
     set voided_at = now(), voided_by = v2.current_person(),
         void_why = coalesce(nullif(btrim(coalesce(p_reason,'')),''),'أُعيد إلى الأصل')
   where o.school_id = p_school and o.voided_at is null
     and o.week_id in (
       select w.id from v2.schools s
         join v2.calendar_years y on y.scope_key = s.calendar_scope
         join v2.calendar_weeks w on w.year_id = y.id
        where s.id = p_school and w.term_no = p_term and w.week_no = p_week);

  get diagnostics v_n = row_count;
  if v_n = 0 then
    raise exception 'هذا الأسبوعُ غيرُ مخصَّصٍ لمدرستك أصلًا — فهو على الأصل';
  end if;

  return jsonb_build_object('ok',true,'term_no',p_term,'week_no',p_week,
    'summary_ar','عاد الأسبوعُ '||p_week||' من الفصل '||p_term||' إلى أصله في تقويم المسار',
    'note_ar','والتخصيصُ السابقُ باقٍ في السجلّ ومعه سببُه ومن أقرّه — لم يُحذف.');
end $function$
;
