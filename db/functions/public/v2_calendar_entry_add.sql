-- public.v2_calendar_entry_add(p_school uuid, p_kind text, p_title text, p_from date, p_to date, p_is_school_day boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ee183158f428a65d9469a2a0655360a0
CREATE OR REPLACE FUNCTION public.v2_calendar_entry_add(p_school uuid, p_kind text, p_title text, p_from date, p_to date DEFAULT NULL::date, p_is_school_day boolean DEFAULT true)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_cyear uuid; v_id uuid;
begin
  perform v2.assert_my_school(p_school,'إضافةَ بندٍ في التقويم');
  perform v2.assert_role(array['principal','deputy','deputy_school','deputy_academic',
    'deputy_school_students','admin_assistant','admin_assistant_students','info_registrar'],
    'إضافةَ بندٍ في التقويم');

  if btrim(coalesce(p_title,'')) = '' then
    raise exception 'عنوانُ البند مطلوبٌ — ولا يُسجَّل بندٌ بلا اسم';
  end if;
  if p_from is null then
    raise exception 'تاريخُ البداية مطلوبٌ — ولا يُسجَّل بندٌ بلا تاريخ';
  end if;
  if p_to is not null and p_to < p_from then
    raise exception 'تاريخُ النهاية قبل تاريخ البداية — فراجِع التاريخين';
  end if;

  select y.id into v_cyear from v2.academic_years y where y.school_id=p_school and y.is_current limit 1;

  insert into v2.calendar_entries (id, school_id, year_id, kind, title, starts_on, ends_on,
                                   is_school_day, source)
  values (gen_random_uuid(), p_school, v_cyear, nullif(btrim(coalesce(p_kind,'')),''),
          btrim(p_title), p_from, p_to, coalesce(p_is_school_day,true), 'بيد المدرسة')
  returning id into v_id;

  return jsonb_build_object('ok',true,'entry',v_id,
    'summary_ar','سُجِّل «'||btrim(p_title)||'» في '||v2.fn_to_hijri(p_from)||' هـ'
      ||case when coalesce(p_is_school_day,true) then '' else ' — وليس يومَ دراسة' end,
    'note_ar','وهذا بندُ مدرستك وحدَها، ولا يظهر في تقويم غيرها.');
end $function$
;
