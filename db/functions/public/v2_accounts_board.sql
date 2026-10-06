-- public.v2_accounts_board(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5b15747ae44656b25268021d9d47bf08
CREATE OR REPLACE FUNCTION public.v2_accounts_board(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy'],'كشف الحسابات');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select jsonb_build_object(
    'staff', (select coalesce(jsonb_agg(jsonb_build_object(
        'person',pe.id,'name',v2.fn_display_name(pe.full_name),
        'role',u.role,'active',u.is_active,
        'posts',(select string_agg(distinct v2.role_ar(a.post_key),' · ')
                  from v2.assignments a
                 where a.person_id=pe.id and a.school_id=p_school and a.ended_on is null))
        order by pe.full_name),'[]'::jsonb)
      from v2.people pe
      join v2.app_users u on u.person_id=pe.id
      where exists (select 1 from v2.assignments a
                     where a.person_id=pe.id and a.school_id=p_school and a.ended_on is null)),
    'guardians', (select jsonb_build_object(
        'total', count(*),
        'with_account', count(*) filter (where g.user_id is not null),
        'portal_open', count(*) filter (where g.portal_active))
      from v2.guardians g
      join v2.enrolments e on e.student_id=g.student_id
                          and e.school_id=p_school and e.status='active'),
    'students', (select jsonb_build_object(
        'total', count(*),
        'with_account', count(*) filter (where s.user_id is not null),
        'portal_open', count(*) filter (where s.portal_active))
      from v2.students s
      join v2.enrolments e on e.student_id=s.id
                          and e.school_id=p_school and e.status='active')
  ) into r;
  return r;
end $function$
;
