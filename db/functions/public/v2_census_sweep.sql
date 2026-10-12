-- public.v2_census_sweep(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9d74e7627ac4de6132d69b0c11bff5cf
CREATE OR REPLACE FUNCTION public.v2_census_sweep(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare n int;
begin
  perform v2.assert_role(array['principal','deputy','deputy_students','deputy_school',
    'deputy_school_students','admin_assistant','admin_assistant_students','counselor'],
    'مسحَ تكاليف الحصر');
  if not v2.my_school(p_school) then raise exception '%', v2.not_my_school_ar(); end if;
  update v2.behavior_census set state='مُعاد',
     returned_why='انقضت المدّةُ ولم يُسلَّم — وعادت إلى الوكيل',
     closed_at=now(), close_why='انقضاء المدّة'
   where school_id=p_school and state='مكلَّف' and due_on < current_date;
  get diagnostics n = row_count;
  return jsonb_build_object('ok',true,'returned',n,
    'note', case when n=0 then 'لا تكليفَ انقضت مدّتُه'
                 else 'عادت '||v2.ar_count(n,'تكليفٌ واحد','تكليفان','تكاليف','تكليفًا')||
                      ' لانقضاء مدّتها' end);
exception
  when not_null_violation or unique_violation or check_violation
    or foreign_key_violation or invalid_datetime_format
    or datetime_field_overflow or invalid_text_representation then
    raise exception '%', v2.say_lock('v2_census_sweep', sqlstate, sqlerrm);
end $function$
;
