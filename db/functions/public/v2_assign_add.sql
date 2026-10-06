-- public.v2_assign_add(p_school uuid, p_person uuid, p_post text, p_letter_no text, p_letter_date date, p_started_on date, p_entitled boolean, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a088fedd0ea22c9f69c674c1679dafc6
CREATE OR REPLACE FUNCTION public.v2_assign_add(p_school uuid, p_person uuid, p_post text, p_letter_no text, p_letter_date date, p_started_on date, p_entitled boolean, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare me uuid; yid uuid; nid uuid;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy'],'إسناد تكليف');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if not exists (select 1 from v2.posts where key=p_post) then
    raise exception 'وظيفةٌ غيرُ معروفة في الملاك'; end if;
  if btrim(coalesce(p_letter_no,''))='' then
    raise exception 'لا تكليفَ بلا رقم خطابٍ — واكتب «بلا رقم» إن لم يكن له رقم'; end if;
  if exists (select 1 from v2.assignments a
              where a.person_id=p_person and a.school_id=p_school
                and a.post_key=p_post and a.ended_on is null) then
    raise exception 'هذا التكليفُ قائمٌ له سلفًا في هذي المدرسة'; end if;

  me := v2.current_person();
  select year_id into yid from v2.enrolments e
   where e.school_id=p_school and e.status='active' limit 1;

  insert into v2.assignments(school_id,post_key,person_id,started_on,is_entitled,year_id,
      letter_no,letter_date,issued_by,issuer_post,reason)
  values (p_school,p_post,p_person,coalesce(p_started_on,current_date),
      coalesce(p_entitled,true),yid,btrim(p_letter_no),p_letter_date,me,v2.my_role(),
      nullif(btrim(coalesce(p_reason,'')),''))
  returning id into nid;
  return jsonb_build_object('ok',true,'assignment',nid);
end $function$
;
