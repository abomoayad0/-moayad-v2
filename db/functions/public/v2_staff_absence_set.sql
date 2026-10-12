-- public.v2_staff_absence_set(p_school uuid, p_person uuid, p_reason text, p_date date, p_from smallint, p_to smallint, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f0f13376664505a3e6db74756d58f4eb
CREATE OR REPLACE FUNCTION public.v2_staff_absence_set(p_school uuid, p_person uuid, p_reason text, p_date date DEFAULT CURRENT_DATE, p_from smallint DEFAULT NULL::smallint, p_to smallint DEFAULT NULL::smallint, p_note text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_id uuid; v_need boolean;
begin
  perform v2.assert_role(array['admin_assistant','deputy_school','principal'],
                         'تسجيل غياب منسوب');
  perform v2.assert_my_school(p_school, 'تسجيل غياب منسوب');
  if not exists (select 1 from v2.staff_absence_reasons where key = p_reason and active) then
    raise exception 'سببٌ غيرُ معروفٍ أو موقوف: %', p_reason;
  end if;
  select needs_note into v_need from v2.staff_absence_reasons where key = p_reason;
  if v_need and coalesce(btrim(p_note),'') = '' then
    raise exception 'هذا السببُ يلزمه بيانٌ مكتوب';
  end if;
  if not exists (select 1 from v2.assignments a
                  where a.person_id = p_person and a.school_id = p_school and a.ended_on is null) then
    raise exception 'هذا المنسوبُ ليس على ملاك مدرستك ولا مكلَّفٌ فيها';
  end if;

  insert into v2.staff_absences(school_id,person_id,on_date,from_period,to_period,
                                reason_key,note_ar,recorded_by)
  values (p_school,p_person,p_date,p_from,p_to,p_reason,nullif(btrim(p_note),''),v2.current_person())
  on conflict (school_id,person_id,on_date) where voided_at is null
  do update set from_period = excluded.from_period, to_period = excluded.to_period,
                reason_key = excluded.reason_key, note_ar = excluded.note_ar,
                recorded_by = excluded.recorded_by, recorded_at = now()
  returning id into v_id;
  return v_id;
end $function$
;
