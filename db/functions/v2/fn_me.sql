-- v2.fn_me()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f50233673f287ddcad5fe2efc34ae1e8
CREATE OR REPLACE FUNCTION v2.fn_me()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
with u as (select * from v2.app_users where id = auth.uid() and is_active),
p as (select pe.* from v2.people pe join u on u.person_id = pe.id),
g as (select coalesce(v2.my_grant(),'operator') grant_level),
r as (select v2.my_role() role_key),
chosen as (select role_key ck, school_id cs from v2.session_role where user_id = auth.uid())
select jsonb_build_object(
 'person_id', p.id, 'name', v2.fn_display_name(p.full_name), 'full_name', p.full_name,
 'grant', (select grant_level from g),
 'grant_ar', case (select grant_level from g)
    when 'owner' then 'صلاحية كاملة' when 'admin' then 'إدارة المدرسة'
    when 'operator' then 'في حدود التكليف' else 'اطّلاع فقط' end,
 'post_key', p.post_key, 'post_ar', v2.role_ar(p.post_key), 'major', p.major_ar,
 'role_key', (select role_key from r), 'role_ar', v2.role_ar((select role_key from r)),
 'acting_chosen', (select ck from chosen) is not null,
 'acting_school', v2.acting_school(),
 'roles', coalesce((select jsonb_agg(jsonb_build_object(
     'role_key',x.role_key,'role_ar',x.role_ar,'source',x.source,
     'school_id',x.school_id,'school',x.school_ar,'is_current',x.is_current))
   from v2.fn_my_roles() x),'[]'::jsonb),
 'schools', coalesce((select jsonb_agg(jsonb_build_object('id',x.id,'name',x.name_ar,
     'stage',x.stage,'students',x.students_n,
     'test_mode',(select test_mode from v2.schools sc where sc.id=x.id)))
   from v2.fn_my_schools() x),'[]'::jsonb),
 'can', jsonb_build_object(
   'record_assembly', v2.can_do(array['admin_assistant','admin_assistant_students',
       'admin_assistant_it','admin_assistant_services','info_registrar','duty_officer']),
   'record_arrival', v2.can_do(array['duty_officer','admin_assistant','admin_assistant_students','info_registrar']),
   'record_dismissal', v2.can_do(array['duty_officer','admin_assistant','admin_assistant_students','guard']),
   'close_day', v2.can_do(array['deputy_students','deputy']),
   'reopen_day', v2.can_do(array['deputy_students','deputy']),
   'decide_excuse', v2.can_do(array['deputy_students','deputy']),
   'record_behavior', v2.can_do(array['counselor','deputy_students','admin_assistant',
       'subject_teacher','sped_teacher','gifted_teacher']),
   'close_task', v2.can_do(array['counselor','deputy_students','admin_assistant','principal']),
   'delegate_task', v2.can_do(array['deputy_students','deputy','principal']),
   'void_form', v2.can_do(array['deputy_students','deputy','principal']),
   'fill_form', v2.my_role() in ('counselor','deputy_students','deputy','principal',
       'admin_assistant','admin_assistant_students','subject_teacher','sped_teacher','gifted_teacher'),
   'record_practice', v2.can_do(array['subject_teacher','sped_teacher','gifted_teacher',
       'counselor','deputy_students','activity_leader']),
   'student_card', true,
   'view_errors', (select grant_level from g) in ('owner','admin'),
   'my_timetable', exists (select 1 from v2.timetable t where t.person_id = p.id),
   'manage_settings', v2.can_do(array['principal','deputy_students','deputy','deputy_academic']),
   -- 🔑 شاشةُ الوكيل لكلّ من يرصد · وأفعالُ الوكيل وحدَه تُحرس في جسورها
   'wakeel', v2.can_do(array['counselor','deputy_students','deputy','principal',
       'admin_assistant','admin_assistant_students','subject_teacher','sped_teacher',
       'gifted_teacher']),
   'wakeel_full', v2.can_do(array['deputy_students','deputy','principal']),
   'muwajjih', v2.can_do(array['counselor']),
   'lajna', exists (select 1 from v2.committee_members m
      where m.person_id = p.id and m.ended_on is null
        and (m.school_id = (select cs from chosen) or (select cs from chosen) is null)),
   'raed', v2.can_do(array['activity_leader'])
      or exists (select 1 from v2.merit_opportunities o
           where o.held_by = p.id and o.state <> 'مُقدَّرة')
      or exists (select 1 from v2.merit_entries x where x.delegated_to = p.id),
   'walee', false, 'talib', false, 'mukallaf', true,
   'merit', v2.can_do(array['activity_leader','deputy_students','deputy','principal'])
      or exists (select 1 from v2.committee_members m
           where m.person_id = p.id and m.committee_key='guidance' and m.ended_on is null)))
from p;
$function$
;
