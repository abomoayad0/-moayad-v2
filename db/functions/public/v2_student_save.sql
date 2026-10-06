-- public.v2_student_save(p_school uuid, p_student uuid, p_full_name text, p_student_no text, p_national_id text, p_nationality text, p_birth_hijri text, p_sex text, p_phone text, p_grade smallint, p_section text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4a9a68ec803f93f08c04d6fc18f7b308
CREATE OR REPLACE FUNCTION public.v2_student_save(p_school uuid, p_student uuid, p_full_name text, p_student_no text, p_national_id text, p_nationality text, p_birth_hijri text, p_sex text, p_phone text, p_grade smallint, p_section text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sid uuid; tn uuid; st text; yid uuid; sc uuid;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy',
      'admin_assistant','admin_assistant_students','info_registrar'],'قيدَ الطلّاب');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if btrim(coalesce(p_full_name,''))='' then raise exception 'اكتب اسمَ الطالب كاملًا'; end if;
  if p_national_id is not null and p_national_id !~ '^[0-9]{10}$' then
    raise exception 'رقمُ الهويّة عشرةُ أرقام'; end if;
  if p_sex is not null and p_sex not in ('ذكر','أنثى') then
    raise exception 'الجنس: «ذكر» أو «أنثى»'; end if;

  select stage, tenant_id into st, tn from v2.schools where id=p_school;
  select year_id into yid from v2.enrolments e
   where e.school_id=p_school and e.status='active' limit 1;

  if p_student is null then
    if btrim(coalesce(p_student_no,''))='' then
      raise exception 'لا يُقيَّد طالبٌ بلا رقمٍ في نور'; end if;
    if p_student_no !~ '^[0-9]{9}$' then
      raise exception 'رقمُ نور تسعةُ أرقام'; end if;
    if exists (select 1 from v2.students where student_no=p_student_no) then
      raise exception 'هذا الرقمُ مقيَّدٌ لطالبٍ آخر'; end if;
    if p_national_id is not null and exists (select 1 from v2.students
         where national_id=p_national_id) then
      raise exception 'هذي الهويّةُ مقيّدةٌ لطالبٍ آخر'; end if;
    if p_grade is null then raise exception 'اختر الصفّ'; end if;
    if btrim(coalesce(p_section,''))='' then raise exception 'اختر الشعبة'; end if;
    if yid is null then
      raise exception 'لا سنةَ دراسيّةٌ فعّالةٌ في هذي المدرسة — أسّس التقويمَ أوّلًا'; end if;

    insert into v2.students(tenant_id,school_id,student_no,national_id,full_name,
        nationality,birth_date_hijri,sex,student_phone,status,reg_status)
    values (tn,p_school,btrim(p_student_no),p_national_id,btrim(p_full_name),
        p_nationality,p_birth_hijri,p_sex,p_phone,'active','مستجد')
    returning id into sid;

    insert into v2.enrolments(student_id,year_id,school_id,stage,grade,section,
        joined_on,status)
    values (sid,yid,p_school,st,p_grade,btrim(p_section),current_date,'active');
    return jsonb_build_object('ok',true,'student',sid,'mode','قُيّد');
  end if;

  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  if sc is distinct from p_school then
    raise exception 'هذا الطالبُ ليس من طلّاب مدرستك'; end if;
  if p_section is not null and btrim(p_section)='' then
    raise exception 'الشعبةُ لا تُترك فارغة'; end if;

  update v2.students set
    full_name=btrim(p_full_name),
    national_id=coalesce(p_national_id,national_id),
    nationality=coalesce(p_nationality,nationality),
    birth_date_hijri=coalesce(p_birth_hijri,birth_date_hijri),
    sex=coalesce(p_sex,sex), student_phone=coalesce(p_phone,student_phone)
   where id=p_student;

  if p_grade is not null or p_section is not null then
    update v2.enrolments set grade=coalesce(p_grade,grade),
                             section=coalesce(btrim(p_section),section)
     where student_id=p_student and school_id=p_school and status='active';
  end if;
  return jsonb_build_object('ok',true,'student',p_student,'mode','عُدّل');
end $function$
;
