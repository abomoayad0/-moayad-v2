-- public.v2_staff_late_record(p_school uuid, p_person uuid, p_date date, p_arrived time without time zone, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f3a5bba97ab63cbf64c8650ae8f20911
CREATE OR REPLACE FUNCTION public.v2_staff_late_record(p_school uuid, p_person uuid, p_date date, p_arrived time without time zone, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_duty time; v_grace int; v_min int; v_fy smallint; v_id uuid; v_k text; nm text; t record;
begin
  perform v2.assert_role(array['admin_assistant','admin_assistant_students','principal',
    'deputy','deputy_school'],'حصرَ تأخّرِ المنسوبين');
  perform v2.assert_my_school(p_school,'حصرَ تأخّرِ المنسوبين');

  if p_date is null then raise exception 'اكتب تاريخَ اليوم الذي تأخّر فيه'; end if;
  if p_date > current_date then
    raise exception 'لا يُحصر تأخّرٌ في يومٍ لم يأتِ — %', v2.fn_to_hijri(p_date); end if;
  if p_arrived is null then raise exception 'اكتب ساعةَ وصوله'; end if;

  if not exists (select 1 from v2.assignments a
                  where a.person_id=p_person and a.school_id=p_school and a.ended_on is null) then
    raise exception 'ليس من منسوبي مدرستك'; end if;

  v_k := v2.fn_day_kind(p_school, p_date);
  if v_k is null or v_k not in ('study','exam') then
    raise exception 'اليوم % ليس يومَ دوامٍ — نوعُه: %', v2.fn_to_hijri(p_date), coalesce(v_k,'غيرُ معروف'); end if;

  v_duty  := v2.staff_duty_at(p_school);
  v_grace := v2.rule_n(p_school,'staff_late_grace_min');
  v_min   := greatest(0, (extract(epoch from (p_arrived - v_duty))/60)::int - v_grace);
  if v_min = 0 then
    raise exception 'وصل الساعةَ % والدوامُ الرسميُّ % (وسماحُ % دقيقة) — فلا تأخّرَ يُحصر',
      v2.time_ar(p_arrived), v2.time_ar(v_duty), v2.ar_num(v_grace); end if;

  v_fy := extract(year from p_date)::smallint;

  insert into v2.staff_lateness(school_id,person_id,on_date,duty_at,arrived_at,minutes_late,
      fiscal_year,note_ar,recorded_by,recorded_role,is_test)
  values (p_school,p_person,p_date,v_duty,p_arrived,v_min,v_fy,p_note,
      v2.current_person(), coalesce(v2.role_ar(v2.my_role()),'المساعد الإداري'),
      coalesce((select test_mode from v2.schools where id=p_school),false))
  on conflict (school_id,person_id,on_date) where voided_at is null
  do update set arrived_at=excluded.arrived_at, minutes_late=excluded.minutes_late,
      duty_at=excluded.duty_at, note_ar=excluded.note_ar,
      recorded_by=excluded.recorded_by, recorded_role=excluded.recorded_role, recorded_at=now()
  returning id into v_id;

  select v2.fn_display_name(full_name) into nm from v2.people where id=p_person;
  select * into t from v2.staff_late_tally(p_school,p_person,v_fy);

  return jsonb_build_object('ok',true,'id',v_id,'minutes',v_min,'person',nm,
    'fiscal_year',v_fy,'total_ar',t.hours_txt,
    'notice_due',t.notice_due,'notice_n',t.notice_n,
    'deduct_days_due',t.deduct_days_due,'deduct_days_done',t.deduct_days_done,
    'summary_ar','حُصر تأخّرُ '||coalesce(nm,'المنسوب')||' '||
      v2.ar_count(v_min,'دقيقةً واحدة','دقيقتين','دقائقَ','دقيقةً')||
      ' — ومجموعُه في عام '||v_fy||': '||t.hours_txt,
    'note_ar', case
      when t.deduct_days_due > t.deduct_days_done then
        '🔴 يجب أمرُ حسمٍ بمقدار '||v2.ar_count(t.deduct_days_due - t.deduct_days_done,
          'يومٍ واحد','يومين','أيّامٍ','يومًا')||' — س-١٦-ا-١ سياسة ٠٣ ص٣٢٦'
      when t.notice_due and t.notice_n = 0 then
        '🔴 بلغ ثلاثَ ساعاتٍ فيجب التنبيه — س-١٦-ا-١ سياسة ٠٣ ص٣٢٦'
      else 'دون عتبةِ التنبيه بعد' end);
exception
  when not_null_violation or unique_violation or check_violation
    or foreign_key_violation or invalid_datetime_format
    or datetime_field_overflow or invalid_text_representation then
    raise exception '%', v2.say_lock('v2_staff_late_record', sqlstate, sqlerrm);
end $function$
;
