-- public.v2_committee_seat(p_school uuid, p_committee text, p_seat_role text, p_person uuid, p_post_key text, p_nominated_by text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 618571e6c5189f616e266c01eaeb9c48
CREATE OR REPLACE FUNCTION public.v2_committee_seat(p_school uuid, p_committee text, p_seat_role text, p_person uuid, p_post_key text, p_nominated_by text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare s record; filled int; cap smallint; nm text; m text; st text; d text; h text; c text;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy'],'تشكيل اللجان');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select * into s from v2.committee_seats
   where committee_key=p_committee and seat_role=p_seat_role
     and (post_key is not distinct from p_post_key) limit 1;
  if s.committee_key is null then
    raise exception 'لا مقعدَ بهذي الصفة في هذي اللجنة — راجع الدليل التنظيميّ'; end if;
  if not exists (select 1 from v2.assignments a
                  where a.person_id=p_person and a.school_id=p_school and a.ended_on is null) then
    raise exception 'هذا المنسوب ليس من منسوبي المدرسة'; end if;
  if s.post_key is not null and not exists (
       select 1 from v2.assignments a where a.person_id=p_person and a.school_id=p_school
          and a.post_key=s.post_key and a.ended_on is null) then
    raise exception 'هذا المقعد لشاغل وظيفةٍ بعينها — ولا يجلس فيه غيرُه'; end if;
  if s.is_elected and btrim(coalesce(p_nominated_by,''))='' then
    raise exception 'هذا المقعد يُختار شاغلُه — فيُكتب من اختاره'; end if;

  select count(*) into filled from v2.committee_members mm
   where mm.committee_key=p_committee and mm.school_id=p_school
     and mm.seat_role=p_seat_role and mm.ended_on is null
     and (mm.via_post_key is not distinct from s.post_key);
  cap := case when s.post_key is null
              then v2.seat_cap(p_school,p_committee,p_seat_role) else s.seat_count end;
  if filled >= cap then
    raise exception 'اكتملت مقاعدُ هذي الصفة في هذي المدرسة (%) — أخرِج عضوًا قبل أن تُجلس آخر', cap; end if;

  if exists (select 1 from v2.committee_members mm
              where mm.committee_key=p_committee and mm.school_id=p_school
                and mm.person_id=p_person and mm.ended_on is null) then
    raise exception 'هذا المنسوب جالسٌ في اللجنة سلفًا'; end if;

  insert into v2.committee_members(school_id,committee_key,person_id,seat_role,
      via_post_key,is_elected,nominated_by,started_on,year_id,term_no)
  select p_school,p_committee,p_person,p_seat_role,s.post_key,s.is_elected,
      nullif(btrim(coalesce(p_nominated_by,'')),''), current_date,
      (select year_id from v2.enrolments e where e.school_id=p_school and e.status='active' limit 1), 1;

  select v2.fn_display_name(full_name) into nm from v2.people where id=p_person;
  return jsonb_build_object('ok',true,'name',nm,'seat',p_seat_role);
exception when others then
  get stacked diagnostics st=returned_sqlstate, m=message_text, d=pg_exception_detail,
    h=pg_exception_hint, c=pg_exception_context;
  perform v2.fn_log_error(m,'v2_committee_seat','اللجان','إجلاس عضو',
    jsonb_build_object('committee',p_committee,'person',p_person),st,d,h,c,'bridge',
    case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', m using errcode = st;
end $function$
;
