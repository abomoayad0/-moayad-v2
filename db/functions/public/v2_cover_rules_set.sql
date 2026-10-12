-- public.v2_cover_rules_set(p_school uuid, p_auto boolean, p_max smallint, p_prefer_subject boolean, p_allow_free boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 428711161b67208c4d19f09f8c706f43
CREATE OR REPLACE FUNCTION public.v2_cover_rules_set(p_school uuid, p_auto boolean DEFAULT NULL::boolean, p_max smallint DEFAULT NULL::smallint, p_prefer_subject boolean DEFAULT NULL::boolean, p_allow_free boolean DEFAULT NULL::boolean)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare x v2.cover_rules;
begin
  perform v2.assert_role(array['principal','deputy_academic','deputy','deputy_school'],
                         'ضبط قواعد تغطية الحصص');
  perform v2.assert_my_school(p_school, 'ضبط قواعد تغطية الحصص');
  x := v2.cover_rules_of(p_school);
  insert into v2.cover_rules(school_id,auto_on,max_per_day,prefer_same_subject,allow_teaching_free,
                             updated_at,updated_by)
  values (p_school,
          coalesce(p_auto, x.auto_on),
          coalesce(p_max,  x.max_per_day),
          coalesce(p_prefer_subject, x.prefer_same_subject),
          coalesce(p_allow_free, x.allow_teaching_free),
          now(), v2.current_person())
  on conflict (school_id) do update
    set auto_on = excluded.auto_on, max_per_day = excluded.max_per_day,
        prefer_same_subject = excluded.prefer_same_subject,
        allow_teaching_free = excluded.allow_teaching_free,
        updated_at = now(), updated_by = excluded.updated_by;
  select * into x from v2.cover_rules where school_id = p_school;
  return 'التوزيعُ الآليّ: ' || case when x.auto_on then 'مشتغل' else 'مطفأ' end ||
         ' · أقصى تغطياتٍ في اليوم: ' || x.max_per_day::text ||
         ' · تقديمُ معلّم المادة: ' || case when x.prefer_same_subject then 'نعم' else 'لا' end ||
         ' · السماحُ بالفارغ: ' || case when x.allow_teaching_free then 'نعم' else 'لا' end;
end $function$
;
