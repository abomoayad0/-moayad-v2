-- v2.ladder_move_class_check(p_record uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 860915c142f882291becd1d9abf60ce7
CREATE OR REPLACE FUNCTION v2.ladder_move_class_check(p_record uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare e record; n int;
begin
  select en.* into e from v2.enrolments en
   where en.student_id = (select student_id from v2.behavior_records where id = p_record)
     and en.status = 'active' limit 1;
  if e.id is null then
    return jsonb_build_object('skip', false); end if;

  select count(*) into n from v2.class_sections cs
   where cs.school_id = e.school_id and cs.year_id = e.year_id
     and cs.grade = e.grade and cs.active and cs.section <> e.section;

  if n = 0 then
    return jsonb_build_object('skip', true,
      'why', 'لا ينطبق: لا فصلَ آخرَ في '||v2.grade_ar(e.grade)||
             ' — فلا محلَّ للنقل · وتُضبط الفصولُ من لوحة التحكّم');
  end if;
  return jsonb_build_object('skip', false, 'targets', n);
end
$function$
;
