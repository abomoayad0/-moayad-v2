-- v2.caller_kind(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 307f5f517509e8bcf3b766abbfa8ed43
CREATE OR REPLACE FUNCTION v2.caller_kind(p_student uuid)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare me uuid; sc uuid; chosen text;
begin
  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;

  -- الطالبُ نفسُه
  if exists (select 1 from v2.students s
              where s.id=p_student and s.user_id = auth.uid() and s.portal_active) then
    return 'student'; end if;

  -- وليُّ الأمر
  if exists (select 1 from v2.guardians g
              where g.student_id=p_student and g.user_id = auth.uid()
                and coalesce(g.portal_active,true)) then
    return 'guardian'; end if;

  me := v2.current_person();
  if me is null then return 'none'; end if;

  -- 🔒 لا يُرى شيءٌ من مدرسةٍ ليس فيها تكليفٌ نافذ
  if not exists (select 1 from v2.assignments a
                  where a.person_id=me and a.school_id=sc and a.ended_on is null)
     and v2.my_grant() not in ('owner','admin') then
    return 'none'; end if;

  -- 🔑 الصفةُ المختارةُ تحكم: فمن اختار صفةً غيرَ الموجّه لا يرى سرَّ الموجّه
  select role_key into chosen from v2.session_role where user_id = auth.uid();

  if chosen is not null then
    if chosen = 'counselor'
       and exists (select 1 from v2.assignments a
                    where a.person_id=me and a.school_id=sc
                      and a.post_key='counselor' and a.ended_on is null)
    then return 'counselor'; end if;
    return 'staff';
  end if;

  -- ولم يختر صفةً: يُؤخذ تكليفُه
  if exists (select 1 from v2.assignments a
              where a.person_id=me and a.school_id=sc
                and a.post_key='counselor' and a.ended_on is null) then
    return 'counselor'; end if;

  return 'staff';
end $function$
;
