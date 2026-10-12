-- public.v2_staff_late_notice(p_school uuid, p_person uuid, p_kind text, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 950a57c445321ec1aa7fe4af9068b704
CREATE OR REPLACE FUNCTION public.v2_staff_late_notice(p_school uuid, p_person uuid, p_kind text, p_why text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare t record; v_fy smallint; v_id uuid; nm text; v_days int;
begin
  perform v2.assert_role(array['admin_assistant','admin_assistant_students','principal','deputy'],
    'إعدادَ تنبيهِ التأخّر أو أمرِ الحسم');
  perform v2.assert_my_school(p_school,'إعدادَ تنبيهِ التأخّر أو أمرِ الحسم');
  if p_kind not in ('notice','deduction') then
    raise exception 'النوعُ تنبيهٌ أو حسمٌ لا غير'; end if;

  v_fy := extract(year from current_date)::smallint;
  select * into t from v2.staff_late_tally(p_school,p_person,v_fy);
  select v2.fn_display_name(full_name) into nm from v2.people where id=p_person;

  if p_kind='notice' then
    if not t.notice_due then
      raise exception 'لم يبلغ عتبةَ التنبيه — تأخّرُه % والعتبةُ % ساعاتٍ', t.hours_txt, v2.ar_num(t.notice_hours); end if;
    if t.notice_n > 0 then
      raise exception 'نُبّه سلفًا في هذا العام الماليّ'; end if;
    v_days := null;
  else
    v_days := t.deduct_days_due - t.deduct_days_done;
    if v_days <= 0 then
      raise exception 'لا يجب حسمٌ جديدٌ — تأخّرُه % ويُحسم يومٌ عن كلّ % ساعاتٍ، وقد سُجّل %',
        t.hours_txt, v2.ar_num(t.per_hours), v2.ar_count(t.deduct_days_done,'يومٌ واحد','يومان','أيّامٍ','يومًا'); end if;
  end if;

  insert into v2.staff_late_actions(school_id,person_id,fiscal_year,kind,at_minutes,days,
      why_ar,prepared_by,is_test)
  values (p_school,p_person,v_fy,p_kind,t.minutes_total,v_days,
      coalesce(nullif(btrim(coalesce(p_why,'')),''),
        case when p_kind='notice' then 'بلغ عتبةَ التنبيه المنصوصة' else 'بلغ موجبَ الحسم المنصوص' end),
      v2.current_person(),
      coalesce((select test_mode from v2.schools where id=p_school),false))
  returning id into v_id;

  return jsonb_build_object('ok',true,'id',v_id,'kind',p_kind,'days',v_days,
    'total_ar',t.hours_txt,
    'summary_ar', case when p_kind='notice'
      then 'أُعدّ تنبيهُ تأخّرٍ لـ'||coalesce(nm,'المنسوب')||' — تأخّرُه '||t.hours_txt
      else 'أُعدّ أمرُ حسمٍ لـ'||coalesce(nm,'المنسوب')||' بمقدار '||
           v2.ar_count(v_days,'يومٍ واحد','يومين','أيّامٍ','يومًا')||' — تأخّرُه '||t.hours_txt end,
    'note_ar', case when p_kind='deduction'
      then 'وأمرُ الحسم لا يصير قرارًا حتى يعتمده مديرُ المدرسة — '||v2.cite_of('hr.deduction_approval')
           ||' · ثمّ يُرفع في فارس ويُكتب مرجعُه بـ v2_staff_late_approve'
      else 'ويُراجع التنبيهُ ويُعتمد ويُرسل للموظّف المعنيّ — '||v2.cite_of('hr.absence_review') end);
end $function$
;
