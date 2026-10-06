-- public.v2_quota_board(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 924bb130a84e7a7506958bd879c2eefd
CREATE OR REPLACE FUNCTION public.v2_quota_board(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select jsonb_build_object(
    'quota', (select coalesce(jsonb_agg(jsonb_build_object(
          'post',q.post_key,'post_ar',v2.role_ar(q.post_key),
          'min',q.min_slots,'min_ar',v2.ar_num(q.min_slots),
          'max',q.max_slots,'max_ar',v2.ar_num(q.max_slots),
          'standby_max',q.standby_max,'note',q.note_ar)
          order by q.max_slots desc),'[]'::jsonb)
        from v2.teaching_quota q where q.school_id=p_school),
    'plan', (select coalesce(jsonb_agg(jsonb_build_object(
          'id',s.id,'grade',s.grade,'grade_ar',v2.ar_num(s.grade),
          'subject',s.subject_ar,'slots',s.slots,'slots_ar',v2.ar_num(s.slots),
          'ord',s.ord) order by s.grade, s.ord, s.subject_ar),'[]'::jsonb)
        from v2.subject_plan s where s.school_id=p_school and s.active),
    'teachers', (select coalesce(jsonb_agg(jsonb_build_object(
          'person_id',pe.id,'person',v2.fn_display_name(pe.full_name),
          'post',(select string_agg(distinct a.post_key,',') from v2.assignments a
                   where a.person_id=pe.id and a.school_id=p_school and a.ended_on is null),
          'subjects',(select coalesce(jsonb_agg(jsonb_build_object(
                'subject',ts.subject_ar,'main',ts.is_main)),'[]'::jsonb)
             from v2.teacher_subjects ts
             where ts.school_id=p_school and ts.person_id=pe.id),
          'now_teaching',(select count(*) from v2.timetable t
             where t.school_id=p_school and t.person_id=pe.id and t.slot_kind='teaching'),
          'now_standby',(select count(*) from v2.timetable t
             where t.school_id=p_school and t.person_id=pe.id and t.slot_kind='standby'),
          'quota_max',(select max(q.max_slots) from v2.teaching_quota q
             join v2.assignments a on a.post_key=q.post_key
             where q.school_id=p_school and a.person_id=pe.id
               and a.school_id=p_school and a.ended_on is null))
          order by pe.full_name),'[]'::jsonb)
        from v2.people pe
        where exists (select 1 from v2.assignments a
                       where a.person_id=pe.id and a.school_id=p_school and a.ended_on is null)),
    'balance', (select jsonb_build_object(
          'planned', (select coalesce(sum(s.slots * (select count(*) from v2.class_sections c
                         where c.school_id=p_school and c.grade=s.grade and c.active)),0)
                      from v2.subject_plan s where s.school_id=p_school and s.active),
          'scheduled', (select count(*) from v2.timetable t
                         where t.school_id=p_school and t.slot_kind='teaching')))
  ) into r;
  return r;
end $function$
;
