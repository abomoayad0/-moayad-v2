-- v2.fn_record_permission(p_student uuid, p_date date, p_out time without time zone, p_reason text, p_requested_by text, p_periods smallint[], p_term smallint, p_by uuid, p_back time without time zone)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 357c03aabd69c1e34ef9eb46ab572914
CREATE OR REPLACE FUNCTION v2.fn_record_permission(p_student uuid, p_date date, p_out time without time zone, p_reason text, p_requested_by text DEFAULT 'guardian'::text, p_periods smallint[] DEFAULT NULL::smallint[], p_term smallint DEFAULT 1, p_by uuid DEFAULT NULL::uuid, p_back time without time zone DEFAULT NULL::time without time zone)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare v_school uuid; v_year uuid; v_id uuid; k text; p smallint;
begin
  select e.school_id,e.year_id into v_school,v_year from v2.enrolments e
   where e.student_id=p_student and e.status='active' order by e.created_at desc limit 1;
  k := v2.fn_day_kind(v_school,p_date);
  if k is null or k not in ('study','exam') then
    raise exception 'اليوم % ليس يوم دراسة — لا استئذان فيه', p_date; end if;
  if btrim(coalesce(p_reason,''))='' then raise exception 'الاستئذان لا يقع بلا سبب مكتوب'; end if;

  insert into v2.student_permissions(school_id,year_id,term_no,student_id,on_date,out_at,back_at,
      returned,reason_ar,requested_by,approved_by,periods_out)
  values (v_school,v_year,p_term,p_student,p_date,p_out,p_back,p_back is not null,
      p_reason,p_requested_by,p_by,p_periods)
  returning id into v_id;

  -- الحصص التي خرج فيها: مستأذن لا هارب
  if p_periods is not null then
    foreach p in array p_periods loop
      insert into v2.period_attendance(school_id,year_id,term_no,student_id,on_date,period_no,state,note)
      values (v_school,v_year,p_term,p_student,p_date,p,'permitted_out','خرج باستئذان — لا يُعدّ هروباً ولا غياباً')
      on conflict (student_id,on_date,period_no) do update
        set state='permitted_out', note='خرج باستئذان — لا يُعدّ هروباً ولا غياباً';
    end loop;
  end if;
  return v_id;
end $function$
;
