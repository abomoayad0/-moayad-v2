-- public.v2_practice_unfork(p_school uuid, p_code text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7db48916d68ca82cc85fc3a6b6482bb9
CREATE OR REPLACE FUNCTION public.v2_practice_unfork(p_school uuid, p_code text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare cur record;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
                         'ضبط ممارسات الصفّ');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select * into cur from v2.class_practices where code=p_code and school_id=p_school;
  if cur.code is null then raise exception 'هذي ليست ممارسةً مفصولةً لمدرستك'; end if;
  if cur.based_on is null then
    raise exception 'هذي ممارسةٌ أنشأتها مدرستُك — ولا أصلَ مشتركَ لها. أخفِها إن شئت'; end if;
  update v2.class_practices set active=false where code=p_code;
  return jsonb_build_object('ok',true,'back_to',cur.based_on);
end $function$
;
