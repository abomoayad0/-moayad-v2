-- v2.fn_record_practice(p_student uuid, p_code text, p_period smallint, p_subject text, p_note text, p_by uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7c4627a98bd14561cf4233bd2b94ced0
CREATE OR REPLACE FUNCTION v2.fn_record_practice(p_student uuid, p_code text, p_period smallint DEFAULT NULL::smallint, p_subject text DEFAULT NULL::text, p_note text DEFAULT NULL::text, p_by uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare cp record; sc uuid; y uuid; t smallint; rid uuid; n int; esc uuid := null; k text;
begin
  select * into cp from v2.class_practices where code=p_code and active;
  if cp.code is null then raise exception 'ممارسة غير معروفة: %', p_code; end if;
  select e.school_id, e.year_id into sc, y from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  if sc is null then raise exception 'الطالب لا قيد فعّال له'; end if;
  k := v2.fn_day_kind(sc, current_date);
  if k is null or k not in ('study','exam') then
    raise exception 'اليوم ليس يوم دراسة — نوعه: %', coalesce(k,'غير معروف'); end if;
  t := v2.fn_term_of(sc, current_date);

  if cp.once_per_day and exists (select 1 from v2.practice_records r
      where r.student_id=p_student and r.code=p_code and r.on_date=current_date and r.undone_at is null) then
    raise exception 'هذه الممارسة لا تُرصد أكثر من مرة في اليوم: %', cp.title_ar; end if;

  insert into v2.practice_records(school_id,year_id,term_no,student_id,code,period_no,subject_ar,
    points,note,by_person,by_role)
  values (sc,y,t,p_student,p_code,p_period,p_subject,
    case when cp.polarity='positive' then cp.points else -1 * greatest(cp.points,0) end,
    p_note, coalesce(p_by,v2.current_person()), v2.role_ar(v2.my_role()))
  returning id into rid;

  if cp.polarity='positive' and cp.points > 0 then
    insert into v2.practice_points(school_id,year_id,term_no,student_id,points,record_id,reason)
    values (sc,y,t,p_student,cp.points,rid,cp.title_ar);
  end if;

  -- التصعيد عند بلوغ الحدّ
  if cp.polarity='negative' and cp.threshold_count is not null then
    select count(*) into n from v2.practice_records r
     where r.student_id=p_student and r.code=p_code and r.undone_at is null
       and (cp.threshold_days is null or r.on_date >= current_date - cp.threshold_days);
    if n >= cp.threshold_count and cp.escalate_to is not null then
      esc := v2.fn_record_behavior(p_student, cp.escalate_to, t, p_period, p_subject,
        'تصعيد آلي: تكرّرت ممارسة «'||cp.title_ar||'» '||n||' مرات'||
        coalesce(' خلال '||cp.threshold_days||' يومًا','')||' — الحدّ '||cp.threshold_count,
        null,false,false,false,false, coalesce(p_by,v2.current_person()));
      update v2.practice_records set escalated_record=esc where id=rid;
    end if;
  end if;

  return jsonb_build_object('record_id',rid,'title',cp.title_ar,'polarity',cp.polarity,
    'points', case when cp.polarity='positive' then cp.points else 0 end,
    'count_so_far', n, 'threshold', cp.threshold_count,
    'escalated', esc is not null, 'escalated_record', esc);
end $function$
;
