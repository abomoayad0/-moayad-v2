-- public.v2_calendar_scope_set(p_school uuid, p_scope text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 61787b2d8900945a1eebf310babd972c
CREATE OR REPLACE FUNCTION public.v2_calendar_scope_set(p_school uuid, p_scope text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_label text; v_weeks int; v_old text;
begin
  perform v2.assert_my_school(p_school,'تحديدَ مسار التقويم');
  perform v2.assert_role(array['principal','deputy','deputy_school','deputy_academic',
    'deputy_school_students','admin_assistant','admin_assistant_students','info_registrar'],
    'تحديدَ مسار التقويم');

  select label_ar into v_label from v2.calendar_scopes where key = btrim(p_scope);
  if v_label is null then
    raise exception 'مسارُ تقويمٍ غيرُ معروف — والمقبولُ: %',
      (select string_agg(key||' ('||label_ar||')', ' · ' order by key) from v2.calendar_scopes);
  end if;

  select count(*) into v_weeks from v2.calendar_weeks w
    join v2.calendar_years y on y.id=w.year_id where y.scope_key = btrim(p_scope);

  select calendar_scope into v_old from v2.schools where id=p_school;
  update v2.schools set calendar_scope = btrim(p_scope) where id = p_school;

  return jsonb_build_object('ok',true,'scope',btrim(p_scope),'label_ar',v_label,
    'weeks_n',v_weeks,'was',v_old,
    'summary_ar','مسارُ مدرستك الآن «'||v_label||'» — و'||
      v2.ar_count(v_weeks,'أسبوعٌ واحدٌ منزَّل','أسبوعان منزَّلان','أسابيعَ منزَّلة','أسبوعًا منزَّلًا'),
    'note_ar', case when v_weeks=0
      then '🔴 وهذا المسارُ بلا أسابيعَ منزَّلة — فلا يُحسب عليه توزيعُ منهج'
      else 'والأسابيعُ مرجعٌ مشتركٌ لا تُعدَّل من مدرسة' end);
end $function$
;
