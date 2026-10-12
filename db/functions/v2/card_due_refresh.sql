-- v2.card_due_refresh(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9e488186a3ae66ec6f7e4950c0dc416f
CREATE OR REPLACE FUNCTION v2.card_due_refresh(p_student uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; n int := 0; d int; r record; v_on int; t1 int; v_scatter int; v_last uuid; v_cnt text;
begin
  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  if sc is null then return 0; end if;
  d := v2.rule_n(sc,'card_step_days');

  for r in
    select ce.code, cp.title_ar, cp.threshold_count, cp.threshold_days,
           count(*)::int cnt,
           (array_agg(ce.person_id order by ce.created_at desc))[1] last_by
      from v2.card_events ce
      join v2.class_practices cp on cp.code=ce.code
     where ce.student_id=p_student and ce.kind='practice' and ce.undone_at is null
       and cp.polarity='negative' and cp.threshold_count is not null
       and cp.escalate_to is null   -- ما يُصعَّد آليًّا إلى الدليل لا تُضاف عليه خطوةُ معلّم
       and (cp.threshold_days is null or ce.on_date >= current_date - cp.threshold_days)
     group by ce.code, cp.title_ar, cp.threshold_count, cp.threshold_days
    having count(*) >= min(cp.threshold_count)
  loop
    v_cnt := case r.cnt when 1 then 'مرّةً' when 2 then 'مرّتين'
                        else v2.ar_num(r.cnt)||' مرّات' end;
    insert into v2.card_due_steps(school_id,student_id,owner_person,kind,code,title_ar,
        n_reached,threshold_n,due_on,is_test)
    values (sc,p_student,r.last_by,'practice_threshold',r.code,
        'تكرّرت «'||r.title_ar||'» '||v_cnt||' — تنبيهُ الطالب ومناقشتُه',
        r.cnt, r.threshold_count, current_date + d,
        coalesce((select test_mode from v2.schools where id=sc),false))
    on conflict do nothing;
    n := n + 1;
  end loop;

  v_scatter := v2.rule_n(sc,'card_scatter_on');
  if v_scatter = 1 then
    t1 := v2.rule_n(sc,'card_scatter_1');
    select (select count(*) from v2.card_events ce
             where ce.student_id=p_student and ce.undone_at is null
               and ce.polarity='negative' and ce.kind='practice')
         + (select count(*) from v2.behavior_records br
             where br.student_id=p_student and br.status <> 'voided')
      into v_on;
    if v_on >= t1 then
      select ce2.person_id into v_last from v2.card_events ce2
        where ce2.student_id=p_student and ce2.undone_at is null
          and ce2.polarity='negative' order by ce2.created_at desc limit 1;
      insert into v2.card_due_steps(school_id,student_id,owner_person,kind,code,title_ar,
          n_reached,threshold_n,due_on,is_test)
      values (sc,p_student,v_last,'scatter',null,
          'بلغت سلبيّاتُه المتفرّقةُ '||v2.ar_num(v_on)||' — تنبيهُ الطالب إلى تعدّد ملاحظاته ومناقشتُه',
          v_on, t1, current_date + d,
          coalesce((select test_mode from v2.schools where id=sc),false))
      on conflict do nothing;
      n := n + 1;
    end if;
  end if;

  return n;
end $function$
;
