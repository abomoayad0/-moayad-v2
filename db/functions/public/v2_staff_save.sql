-- public.v2_staff_save(p_school uuid, p_person uuid, p_full_name text, p_national_id text, p_employee_no text, p_phone text, p_email text, p_major text, p_rank text, p_qualification text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2f12997b42d8324cf200e2907946a4a3
CREATE OR REPLACE FUNCTION public.v2_staff_save(p_school uuid, p_person uuid, p_full_name text, p_national_id text, p_employee_no text, p_phone text, p_email text, p_major text, p_rank text, p_qualification text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare pid uuid; tn uuid;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy'],'إضافة منسوب أو تعديله');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if btrim(coalesce(p_full_name,''))='' then raise exception 'اكتب الاسمَ كاملًا'; end if;
  if p_national_id is not null and p_national_id !~ '^[0-9]{10}$' then
    raise exception 'رقمُ الهويّة عشرةُ أرقام'; end if;
  if p_phone is not null and p_phone !~ '^[0-9+]{9,15}$' then
    raise exception 'رقمُ الجوّال غيرُ صحيح'; end if;

  if p_person is null then
    if p_national_id is not null and exists (select 1 from v2.people where national_id=p_national_id) then
      raise exception 'هذي الهويّةُ مسجّلةٌ لمنسوبٍ آخر'; end if;
    select tenant_id into tn from v2.schools where id=p_school;
    insert into v2.people(full_name,national_id,employee_no,phone,email,
        major_ar,rank_key,qualification_ar,status,tenant_id)
    values (btrim(p_full_name),p_national_id,p_employee_no,p_phone,p_email,
        p_major,p_rank,p_qualification,'active',tn)
    returning id into pid;
    return jsonb_build_object('ok',true,'person',pid,'mode','أُضيف',
      'note','ولا يعمل حتى يُسند له تكليف');
  end if;

  if not exists (select 1 from v2.assignments a
                  where a.person_id=p_person and a.school_id=p_school and a.ended_on is null)
     and v2.my_grant() not in ('owner','admin') then
    raise exception 'هذا المنسوب ليس من منسوبي مدرستك'; end if;

  update v2.people set
    full_name=btrim(p_full_name),
    national_id=coalesce(p_national_id,national_id),
    employee_no=coalesce(p_employee_no,employee_no),
    phone=coalesce(p_phone,phone), email=coalesce(p_email,email),
    major_ar=coalesce(p_major,major_ar), rank_key=coalesce(p_rank,rank_key),
    qualification_ar=coalesce(p_qualification,qualification_ar)
   where id=p_person;
  return jsonb_build_object('ok',true,'person',p_person,'mode','عُدّل');
end $function$
;
