-- public.v2_assign_add(p_school uuid, p_person uuid, p_post text, p_letter_no text, p_letter_date date, p_started_on date, p_entitled boolean, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 15ab7c171ef6d6168e02a498af696a54
CREATE OR REPLACE FUNCTION public.v2_assign_add(p_school uuid, p_person uuid, p_post text, p_letter_no text DEFAULT NULL::text, p_letter_date date DEFAULT NULL::date, p_started_on date DEFAULT NULL::date, p_entitled boolean DEFAULT NULL::boolean, p_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare me uuid; yid uuid; nid uuid; other_school text; nm text; pl text; isr text;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy'],'إسناد تكليف');
  if not v2.my_school(p_school) then raise exception '%', v2.not_my_school_ar(); end if;
  if not exists (select 1 from v2.people where id=p_person) then
    raise exception 'منسوبٌ غيرُ موجود'; end if;
  if not exists (select 1 from v2.posts where key=p_post) then
    raise exception 'وظيفةٌ غيرُ معروفة في الملاك'; end if;
  if p_letter_date is not null and p_letter_date > current_date then
    raise exception 'تاريخُ الخطاب لم يأتِ بعد'; end if;

  if exists (select 1 from v2.assignments a where a.person_id=p_person and a.ended_on is null)
     and not exists (select 1 from v2.assignments a
                      where a.person_id=p_person and a.school_id=p_school and a.ended_on is null)
     and btrim(coalesce(p_reason,''))='' then
    select string_agg(distinct s.name_ar,' · ') into other_school
      from v2.assignments a join v2.schools s on s.id=a.school_id
     where a.person_id=p_person and a.ended_on is null;
    raise exception 'هذا المنسوب يعمل في «%» — فاكتب سببَ تكليفه في مدرستك', other_school;
  end if;

  if exists (select 1 from v2.assignments a
              where a.person_id=p_person and a.school_id=p_school
                and a.post_key=p_post and a.ended_on is null) then
    raise exception 'هذا التكليفُ قائمٌ له سلفًا في هذي المدرسة'; end if;

  me  := v2.current_person();
  isr := v2.assign_issuer_post();
  select year_id into yid from v2.enrolments e
   where e.school_id=p_school and e.status='active' limit 1;

  insert into v2.assignments(school_id,post_key,person_id,started_on,is_entitled,year_id,
      letter_no,letter_date,issued_by,issuer_post,reason)
  values (p_school,p_post,p_person,coalesce(p_started_on,current_date),
      coalesce(p_entitled,true),yid,
      nullif(btrim(coalesce(p_letter_no,'')),''), p_letter_date,
      me, isr, nullif(btrim(coalesce(p_reason,'')),''))
  returning id into nid;

  select v2.fn_display_name(full_name) into nm from v2.people where id=p_person;
  pl := coalesce((select label_ar from v2.posts where key=p_post), p_post);

  return jsonb_build_object('ok',true,'assignment',nid,
    'issuer_post', isr,
    'issuer_ar', coalesce(v2.role_ar(isr), case when isr='owner' then 'مالك النظام' else isr end),
    'letter_pending', nullif(btrim(coalesce(p_letter_no,'')),'') is null or p_letter_date is null,
    'said_ar', format('كُلِّف %s بـ«%s» — بإسنادٍ من %s%s',
      coalesce(nm,'المنسوب'), pl,
      coalesce(v2.role_ar(isr), case when isr='owner' then 'مالك النظام' else isr end),
      case when nullif(btrim(coalesce(p_letter_no,'')),'') is null or p_letter_date is null
           then ' · وخطابُه لم يُستكمل بعد، فهو في لوحة «خلل» حتى يُكتب رقمُه وتاريخُه'
           else '' end));
end $function$
;
