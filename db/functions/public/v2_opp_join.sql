-- public.v2_opp_join(p_opp uuid, p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6014a8a0b502081dbdc2f68a62637fd5
CREATE OR REPLACE FUNCTION public.v2_opp_join(p_opp uuid, p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare o record; n int; who text;
begin
  who := v2.caller_kind(p_student);
  if who not in ('student','guardian') then
    perform v2.assert_role(array['deputy_students','deputy','principal','activity_leader','counselor'],
      'تسجيلَ طالبٍ في فرصة تعويض نيابةً عنه');
    perform v2.assert_my_student(p_student,'تسجيل في فرصة تعويض');
    who := 'نيابةً — '||coalesce(v2.role_ar(v2.my_role()),'منسوب');
  else
    who := case who when 'student' then 'الطالب' else 'وليّ الأمر' end; end if;

  select * into o from v2.merit_opportunities where id=p_opp;
  if o.id is null then raise exception 'الفرصةُ غيرُ موجودة'; end if;
  if o.state <> 'مفتوحة' then raise exception 'الفرصةُ % — %', o.state, coalesce(o.close_why,''); end if;
  insert into v2.merit_entries(opp_id,student_id,joined_by,joined_as)
  values (p_opp,p_student,v2.current_person(),who)
   on conflict (opp_id,student_id) do nothing;
  select count(*) into n from v2.merit_entries where opp_id=p_opp;
  if o.capacity is not null and n >= o.capacity then
    update v2.merit_opportunities set state='مُغلقة', close_why='اكتمل العدد',
      closed_at=now() where id=p_opp; end if;
  return jsonb_build_object('ok',true,'taken',n,'capacity',o.capacity,'by',who,
    'upload_to', v2.evidence_path_for(
      (select id from v2.merit_entries where opp_id=p_opp and student_id=p_student)));
end $function$
;
