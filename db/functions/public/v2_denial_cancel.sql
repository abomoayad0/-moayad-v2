-- public.v2_denial_cancel(p_decision uuid, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 dfa392d57e9849d897163d57f9f2a393
CREATE OR REPLACE FUNCTION public.v2_denial_cancel(p_decision uuid, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare d record; v_id uuid;
begin
  perform v2.assert_role(array['principal'],'إلغاءَ قرار الحرمان');
  select * into d from v2.denial_actions where id=p_decision and kind='decision';
  if d.id is null then raise exception 'لا قرارَ حرمانٍ بهذا المعرّف'; end if;
  perform v2.assert_my_school(d.school_id,'إلغاءَ قرار الحرمان');
  if length(btrim(coalesce(p_reason,''))) < 10 then
    raise exception 'الإلغاءُ لا يقع بلا سببٍ مكتوب'; end if;
  if exists (select 1 from v2.denial_actions c where c.kind='cancel'
              and c.committee_entry = p_decision) then
    raise exception 'أُلغي هذا القرارُ سلفًا'; end if;

  insert into v2.denial_actions(school_id,student_id,year_id,kind,days_absent,limit_days,
      committee_entry,reason,by_person,is_test)
  values (d.school_id,d.student_id,d.year_id,'cancel',d.days_absent,d.limit_days,
      p_decision,btrim(p_reason),v2.current_person(),d.is_test)
  returning id into v_id;

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,is_test)
  values (d.school_id,'absence_report',current_date,d.student_id,
      'أُلغي قرارُ الحرمان من الانتقال', btrim(p_reason),
      'denial_actions',v_id,'all',d.is_test);

  perform v2.log_action(d.school_id,d.student_id,'denial_cancel','أُلغي قرارُ الحرمان',
    'denial_actions',v_id, jsonb_build_object('of',p_decision));

  return jsonb_build_object('ok',true,'cancel',v_id,
    'note_ar','أُلغي القرارُ — والقرارُ الأوّلُ وسببُ إلغائه كلاهما باقيان في السجلّ');
end $function$
;
