-- public.v2_attendance_rollup(p_level text, p_from date, p_to date, p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7661dac0c379136cea7c07d33d6befd5
CREATE OR REPLACE FUNCTION public.v2_attendance_rollup(p_level text DEFAULT 'school'::text, p_from date DEFAULT NULL::date, p_to date DEFAULT NULL::date, p_school uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; yr uuid; rows jsonb; n integer;
begin
  perform v2.assert_role(array['principal','deputy','deputy_students',
      'admin_assistant','admin_assistant_students','counselor'],'مجمَّع المواظبة');
  sc := coalesce(p_school, v2.acting_school());
  perform v2.assert_my_school(sc,'مجمَّع المواظبة');
  if p_level not in ('school','grade','section') then
    raise exception 'المستوى «%» غيرُ معروف — وهي: school · grade · section', p_level;
  end if;
  select id into yr from v2.academic_years where school_id = sc and is_current limit 1;

  select coalesce(jsonb_agg(to_jsonb(q)),'[]'::jsonb) into rows
    from v2.fn_register_rollup(p_level, sc, yr, p_from, p_to) q;
  n := jsonb_array_length(rows);

  return jsonb_build_object('rows', rows, 'count', n, 'level', p_level,
    'level_ar', case p_level when 'school' then 'المدرسة'
                             when 'grade' then 'الصفّ' else 'الفصل' end,
    'summary_ar', case when n = 0 then 'لا بياناتٍ في هذا المدى'
      else v2.ar_count(n,'سطرٌ واحد','سطران','أسطر','سطرًا')||' في المجمَّع' end,
    'note_ar','ولا يُعرض في هذا التقرير اسمُ طالبٍ ولا ترتيبُه — فهو مجمَّعٌ للإدارة');
end $function$
;
