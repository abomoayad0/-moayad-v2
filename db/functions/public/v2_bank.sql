-- public.v2_bank(p_key text, p_problem integer, p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3c424b01b8f9d22dde662988e4b802ca
CREATE OR REPLACE FUNCTION public.v2_bank(p_key text, p_problem integer, p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb; me uuid;
begin
  if auth.uid() is null then raise exception 'لا بدّ من تسجيل الدخول'; end if;
  me := v2.current_person();
  if me is null then
    raise exception 'بنكُ العبارات لفريق المدرسة — وكلامُك شهادةٌ لا تُملى عليك'; end if;
  if p_school is not null and not v2.my_school(p_school) then
    raise exception 'ليست مدرستك'; end if;

  select coalesce(jsonb_agg(jsonb_build_object('id',b.id,'text',b.text_ar,'ord',b.ord,
      'mine',(b.school_id is not null))
      order by (b.problem_id is null), b.ord),'[]'::jsonb)
  into r from v2.phrase_bank b
  where b.active and b.bank_key=p_key
    and (b.school_id is null or b.school_id=p_school)
    and (b.problem_id is null or b.problem_id=p_problem);
  return r;
end $function$
;
