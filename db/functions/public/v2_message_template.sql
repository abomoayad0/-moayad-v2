-- public.v2_message_template(p_school uuid, p_key text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3a41fd79cbb98fb0f4861fb712cf3106
CREATE OR REPLACE FUNCTION public.v2_message_template(p_school uuid, p_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r record;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select body_ar, school_id into r from v2.message_templates
   where key=coalesce(p_key,'guardian_notice') and active
     and (school_id is null or school_id=p_school)
   order by (school_id is null) limit 1;
  return jsonb_build_object('body',r.body_ar,'mine',(r.school_id is not null),
    'vars', jsonb_build_array('{المدرسة}','{الطالب}','{الفصل}','{السلوك}',
      '{الرصدة}','{الأثر}','{الموقّع}'));
end $function$
;
