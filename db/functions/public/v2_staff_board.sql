-- public.v2_staff_board(p_school uuid, p_q text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6aa5add5aa8cf0b0a72dec72f548042f
CREATE OR REPLACE FUNCTION public.v2_staff_board(p_school uuid, p_q text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic',
                               'admin_assistant','admin_assistant_students'],'كشف المنسوبين');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'person',pe.id,'name',pe.full_name,'display',v2.fn_display_name(pe.full_name),
      'national_id',pe.national_id,'employee_no',pe.employee_no,
      'phone',pe.phone,'email',pe.email,
      'major',pe.major_ar,'rank',pe.rank_key,'qualification',pe.qualification_ar,
      'status',pe.status,'status_changed_on',pe.status_changed_on,
      'seconded',pe.is_seconded_partial,
      'posts',(select coalesce(jsonb_agg(jsonb_build_object(
           'assignment',a.id,'post',a.post_key,'post_ar',v2.role_ar(a.post_key),
           'school',s.name_ar,'school_id',a.school_id,
           'letter_no',a.letter_no,'letter_date',a.letter_date,
           'started_on',a.started_on,'entitled',a.is_entitled,
           'reason',a.reason) order by a.started_on desc),'[]'::jsonb)
         from v2.assignments a join v2.schools s on s.id=a.school_id
         where a.person_id=pe.id and a.ended_on is null),
      'has_account',exists (select 1 from v2.app_users u where u.person_id=pe.id and u.is_active))
      order by pe.full_name),'[]'::jsonb)
  into r from v2.people pe
  where exists (select 1 from v2.assignments a
                 where a.person_id=pe.id and a.school_id=p_school and a.ended_on is null)
    and (p_q is null or pe.full_name ilike '%'||p_q||'%'
         or coalesce(pe.national_id,'') like '%'||p_q||'%');
  return r;
end $function$
;
