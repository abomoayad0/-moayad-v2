-- public.v2_guardian_save(p_student uuid, p_guardian uuid, p_full_name text, p_relation text, p_national_id text, p_phone text, p_work_phone text, p_home_phone text, p_workplace text, p_is_primary boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7864961b2a71c8d0bf6e9f9b1c800b72
CREATE OR REPLACE FUNCTION public.v2_guardian_save(p_student uuid, p_guardian uuid, p_full_name text, p_relation text, p_national_id text, p_phone text, p_work_phone text, p_home_phone text, p_workplace text, p_is_primary boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare gid uuid;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy',
      'admin_assistant','admin_assistant_students','info_registrar','counselor'],
      'بياناتِ أولياء الأمور');
  perform v2.assert_my_student(p_student,'بيانات وليّ الأمر');
  if btrim(coalesce(p_full_name,''))='' then raise exception 'اكتب اسمَ وليّ الأمر'; end if;
  if btrim(coalesce(p_relation,''))='' then raise exception 'اكتب صلتَه بالطالب'; end if;

  if not exists (select 1 from v2.guardian_relations g
                  where g.active and g.label_ar = btrim(p_relation)) then
    raise exception 'صلةٌ غيرُ معروفة «%» — والمقبولُ: %', btrim(p_relation),
      (select string_agg(g.label_ar, ' · ' order by g.ord) from v2.guardian_relations g where g.active);
  end if;

  if p_phone is not null and p_phone !~ '^[0-9+]{9,15}$' then
    raise exception 'رقمُ الجوّال غيرُ صحيح'; end if;
  if p_national_id is not null and p_national_id !~ '^[0-9]{10}$' then
    raise exception 'رقمُ الهويّة عشرةُ أرقام'; end if;

  if p_guardian is null then
    insert into v2.guardians(student_id,full_name,relation,national_id,phone,
        work_phone,home_phone,workplace_ar,is_primary)
    values (p_student,btrim(p_full_name),btrim(p_relation),p_national_id,p_phone,
        p_work_phone,p_home_phone,p_workplace,coalesce(p_is_primary,false))
    returning id into gid;
  else
    if not exists (select 1 from v2.guardians where id=p_guardian and student_id=p_student) then
      raise exception 'وليُّ الأمر هذا ليس لهذا الطالب'; end if;
    update v2.guardians set
      full_name=btrim(p_full_name), relation=btrim(p_relation),
      national_id=coalesce(p_national_id,national_id),
      phone=coalesce(p_phone,phone), work_phone=coalesce(p_work_phone,work_phone),
      home_phone=coalesce(p_home_phone,home_phone),
      workplace_ar=coalesce(p_workplace,workplace_ar),
      is_primary=coalesce(p_is_primary,is_primary)
     where id=p_guardian;
    gid := p_guardian;
  end if;

  if coalesce(p_is_primary,false) then
    update v2.guardians set is_primary=false
     where student_id=p_student and id<>gid;
  end if;
  return jsonb_build_object('ok',true,'guardian',gid,
    'said_ar','حُفظ «'||btrim(p_full_name)||'» — '||btrim(p_relation));
exception
  when not_null_violation or unique_violation or check_violation
    or foreign_key_violation or invalid_datetime_format
    or datetime_field_overflow or invalid_text_representation then
    raise exception '%', v2.say_lock('v2_guardian_save', sqlstate, sqlerrm);
end $function$
;
