-- v2.plan_reviewers(p_school uuid, p_subject text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f2690a0025fdb75904a1a5e0471a2697
CREATE OR REPLACE FUNCTION v2.plan_reviewers(p_school uuid, p_subject text)
 RETURNS TABLE(person_id uuid, rank_key text, rank_ar text, full_name text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select pe.id, pe.rank_key, tr.label_ar, pe.full_name
    from v2.people pe
    join v2.assignments a on a.person_id=pe.id and a.school_id=p_school and a.ended_on is null
    left join v2.teaching_ranks tr on tr.key=pe.rank_key
   where pe.rank_key in ('expert','advanced')
     and (exists (select 1 from v2.teacher_subjects ts
                   where ts.school_id=p_school and ts.person_id=pe.id
                     and ts.subject_ar=btrim(p_subject))
       or exists (select 1 from v2.timetable t
                   where t.school_id=p_school and t.person_id=pe.id
                     and t.subject_ar=btrim(p_subject)))
   order by case pe.rank_key when 'expert' then 1 else 2 end
$function$
;
