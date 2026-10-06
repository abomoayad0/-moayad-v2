-- v2.fn_quick_day(p_school text, p_date date, p_absent text[], p_late text[], p_late_minutes smallint, p_missed_assembly text[], p_by uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a726cf3f291c19fd0b9cb2d1977d33da
CREATE OR REPLACE FUNCTION v2.fn_quick_day(p_school text, p_date date DEFAULT CURRENT_DATE, p_absent text[] DEFAULT '{}'::text[], p_late text[] DEFAULT '{}'::text[], p_late_minutes smallint DEFAULT 15, p_missed_assembly text[] DEFAULT '{}'::text[], p_by uuid DEFAULT NULL::uuid)
 RETURNS TABLE("المدرسة" text, "اليوم" text, "حاضر" integer, "غائب" integer, "متأخر" integer, "تخلف_عن_الاصطفاف" integer, "لم_يُطابق" text)
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; k text; r record; n_p int:=0; n_a int:=0; n_l int:=0; n_m int:=0;
  miss text[]:='{}'; sid uuid; nm text; st record;
begin
  select id into sc from v2.schools where name_ar like '%'||p_school||'%' limit 1;
  if sc is null then raise exception 'لا مدرسة باسم يشبه: %', p_school; end if;
  k := v2.fn_day_kind(sc,p_date);
  if k is null or k not in ('study','exam') then
    raise exception 'اليوم % ليس يوم دراسة — نوعه: %', p_date, coalesce(k,'غير معروف'); end if;
  if exists (select 1 from v2.day_closures c where c.school_id=sc and c.on_date=p_date and c.reopened_at is null) then
    raise exception 'يوم % مقفَل. أعد فتحه أولاً بسبب مكتوب', p_date; end if;

  -- الجميع حاضر
  for r in select e.student_id sid from v2.enrolments e where e.school_id=sc and e.status='active' loop
    perform v2.fn_record_assembly(r.sid, p_date, 'attended', 1::smallint, p_by, 'المساعد الإداري');
    n_p := n_p + 1;
  end loop;

  -- من تخلّف عن الاصطفاف وهو داخل المدرسة
  foreach nm in array p_missed_assembly loop
    select s.id into sid from v2.students s join v2.enrolments e on e.student_id=s.id and e.school_id=sc and e.status='active'
     where s.full_name like '%'||nm||'%' limit 1;
    if sid is null then miss := miss || nm; continue; end if;
    perform v2.fn_record_assembly(sid, p_date, 'missed_inside', 1::smallint, p_by, 'المناوب');
    n_m := n_m + 1;
  end loop;

  -- الغائبون
  foreach nm in array p_absent loop
    select s.id into sid from v2.students s join v2.enrolments e on e.student_id=s.id and e.school_id=sc and e.status='active'
     where s.full_name like '%'||nm||'%' limit 1;
    if sid is null then miss := miss || nm; continue; end if;
    perform v2.fn_record_assembly(sid, p_date, 'not_arrived', 1::smallint, p_by, 'المساعد الإداري');
    n_a := n_a + 1; n_p := n_p - 1;
  end loop;

  -- المتأخرون
  foreach nm in array p_late loop
    select s.id into sid from v2.students s join v2.enrolments e on e.student_id=s.id and e.school_id=sc and e.status='active'
     where s.full_name like '%'||nm||'%' limit 1;
    if sid is null then miss := miss || nm; continue; end if;
    select * into st from v2.day_settings where school_id=sc;
    perform v2.fn_record_assembly(sid, p_date, 'not_arrived', 1::smallint, p_by, 'المناوب');
    perform v2.fn_record_arrival(sid, p_date,
      st.assembly_at + make_interval(mins => p_late_minutes), 'enter_class', 1::smallint, p_by);
    n_l := n_l + 1; n_p := n_p - 1;
  end loop;

  return query select (select name_ar from v2.schools where id=sc),
    v2.fn_to_hijri(p_date)||' · '||p_date::text, n_p, n_a, n_l, n_m,
    case when array_length(miss,1) is null then '—' else array_to_string(miss,' · ') end;
end $function$
;
