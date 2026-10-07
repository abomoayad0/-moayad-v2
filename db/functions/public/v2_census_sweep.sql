-- public.v2_census_sweep(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9f0283438acfda5421d1f58a6e7b6f7f
CREATE OR REPLACE FUNCTION public.v2_census_sweep(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare n int;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  update v2.behavior_census set state='مُعاد',
     returned_why='انقضت المدّةُ ولم يُسلَّم — وعادت إلى الوكيل',
     closed_at=now(), close_why='انقضاء المدّة'
   where school_id=p_school and state='مكلَّف' and due_on < current_date;
  get diagnostics n = row_count;
  return jsonb_build_object('ok',true,'returned',n,
    'note', case when n=0 then 'لا تكليفَ انقضت مدّتُه'
                 else 'عادت '||v2.ar_num(n)||' من التكاليف لانقضاء مدّتها' end);
end $function$
;
