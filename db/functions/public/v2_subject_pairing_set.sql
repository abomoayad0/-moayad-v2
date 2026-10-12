-- public.v2_subject_pairing_set(p_school uuid, p_subject text, p_mode text, p_max smallint, p_grade smallint, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a982a0e049c5926db3221f262da53b24
CREATE OR REPLACE FUNCTION public.v2_subject_pairing_set(p_school uuid, p_subject text, p_mode text, p_max smallint DEFAULT NULL::smallint, p_grade smallint DEFAULT NULL::smallint, p_note text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_max smallint;
begin
  perform v2.assert_role(array['principal','deputy_academic','deputy','deputy_school'],
                         'ضبط قاعدة بثّ المادّة');
  perform v2.assert_my_school(p_school, 'ضبط قاعدة بثّ المادّة');
  if p_mode not in ('joined','split','free') then
    raise exception 'القاعدةُ إمّا متّصلةٌ joined أو منفصلةٌ split أو مطلقةٌ free — لا %', p_mode;
  end if;
  v_max := coalesce(p_max, case p_mode when 'joined' then 2 when 'split' then 1 else 4 end);
  if p_mode = 'split' and v_max <> 1 then
    raise exception 'المنفصلةُ مرّةٌ واحدةٌ في اليوم بحكمها — فإن أردتَ أكثرَ فهي متّصلةٌ أو مطلقة';
  end if;
  insert into v2.subject_pairing(school_id,grade,subject_ar,mode,max_per_day,note_ar,set_by)
  values (p_school,p_grade,btrim(p_subject),p_mode,v_max,
          nullif(btrim(coalesce(p_note,'')),''),v2.current_person())
  on conflict (school_id, coalesce(grade,-1), subject_ar)
  do update set mode = excluded.mode, max_per_day = excluded.max_per_day,
                note_ar = excluded.note_ar, set_by = excluded.set_by, set_at = now();
  return btrim(p_subject) || ' · ' ||
    case p_mode when 'joined' then 'متّصلة' when 'split' then 'منفصلة' else 'مطلقة' end ||
    ' · حتّى ' || v2.ar_count(v_max,'حصّة','حصّتان','حصص','حصّة') || ' في اليوم' ||
    coalesce(' · ' || (select label_ar from v2.class_sections where school_id=p_school and grade=p_grade limit 1), ' · كلّ الصفوف');
end $function$
;
