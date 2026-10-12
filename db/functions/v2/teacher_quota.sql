-- v2.teacher_quota(p_school uuid, p_person uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 545d534ac2ec2fa806d0053823bf8b12
CREATE OR REPLACE FUNCTION v2.teacher_quota(p_school uuid, p_person uuid)
 RETURNS integer
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_rank text; v_sped boolean; v_per int;
begin
  select pe.rank_key into v_rank from v2.people pe where pe.id = p_person;

  v_sped := exists (select 1 from v2.assignments a
                     where a.person_id=p_person and a.school_id=p_school
                       and a.ended_on is null
                       and a.post_key in ('sped_teacher','sped_teacher_assistant'));

  select tl.periods into v_per
    from v2.teaching_loads tl
   where tl.scope_ar = case when v_sped then 'معلم التربية الخاصة' else 'معلمو المواد الدراسية' end
     and tl.rank_ar = case coalesce(v_rank,'practitioner')
       when 'expert'  then case when v_sped then 'معلم التربية الخاصة — خبير'  else 'المعلم الخبير'  end
       when 'advanced'then case when v_sped then 'معلم التربية الخاصة — متقدم' else 'المعلم المتقدم' end
       else            case when v_sped then 'معلم التربية الخاصة — ممارس' else 'المعلم الممارس' end
     end
   limit 1;

  return coalesce(v_per, case when v_sped then 16 else 24 end);
end $function$
;
