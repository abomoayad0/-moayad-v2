-- v2.fn_record_behavior(p_student uuid, p_problem integer, p_term smallint, p_period smallint, p_place text, p_note text, p_victim uuid, p_injury boolean, p_damage boolean, p_seizure boolean, p_seizure_legal boolean, p_by uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 be1bc6b6c39549c7cd59122d8e882d73
CREATE OR REPLACE FUNCTION v2.fn_record_behavior(p_student uuid, p_problem integer, p_term smallint DEFAULT 1, p_period smallint DEFAULT NULL::smallint, p_place text DEFAULT NULL::text, p_note text DEFAULT NULL::text, p_victim uuid DEFAULT NULL::uuid, p_injury boolean DEFAULT false, p_damage boolean DEFAULT false, p_seizure boolean DEFAULT false, p_seizure_legal boolean DEFAULT false, p_by uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare
  v_school uuid; v_year uuid; v_stage text; v_mode text := 'onsite';
  v_prob record; v_scope text; v_count int; v_step int; v_max int; v_action record;
  v_rec uuid; v_ded numeric; v_open numeric; it record; un record;
  v_skip boolean; v_why text; v_beyond boolean; v_same record; v_who text;
begin
  select e.school_id, e.year_id, e.stage into v_school, v_year, v_stage
  from v2.enrolments e where e.student_id=p_student and e.status='active'
  order by e.created_at desc limit 1;
  if v_school is null then raise exception 'الطالب لا قيد فعّال له في سنة دراسية'; end if;

  select * into v_prob from v2.conduct_problems where id=p_problem;
  if v_prob.id is null then raise exception 'المخالفة غير معروفة'; end if;
  v_scope := case when v_stage='primary' then 'primary' else 'intermediate_secondary' end;
  if v_prob.stage_scope not in (v_scope,'all') then raise exception 'هذه المخالفة لا تنطبق على مرحلة الطالب'; end if;
  if v_prob.mode <> v_mode then raise exception 'نمط التعليم لا يطابق'; end if;

  -- 🔒 قفلُ الواقعة الواحدة: أوّلُ من يدوّن يُقفل البابَ على الباقين في ذلك اليوم
  select r.*, r.created_at::date as on_day into v_same
    from v2.behavior_records r
   where r.student_id=p_student and r.problem_id=p_problem
     and r.status<>'voided' and r.created_at::date = current_date
   limit 1;
  if v_same.id is not null then
    select coalesce(v2.fn_display_name(pe.full_name),'غيرُك') into v_who
      from v2.people pe where pe.id = v_same.recorded_by;
    raise exception 'دُوّنت هذي المخالفةُ على الطالب اليومَ سلفًا — دوّنها % · ولا تُدوَّن الواقعةُ مرّتين', v_who;
  end if;

  select count(*) into v_count from v2.behavior_records r
   where r.student_id=p_student and r.problem_id=p_problem and r.year_id=v_year and r.status<>'voided';
  select max(step_no) into v_max from v2.conduct_actions
   where degree_no=v_prob.degree_no and stage_scope=v_prob.stage_scope and mode=v_prob.mode and target=v_prob.target;

  v_beyond := (v_count + 1) > v_max;
  v_step   := least(v_count+1, v_max);

  select * into v_action from v2.conduct_actions
   where degree_no=v_prob.degree_no and stage_scope=v_prob.stage_scope
     and mode=v_prob.mode and target=v_prob.target and step_no=v_step;

  insert into v2.behavior_records(school_id,year_id,term_no,student_id,problem_id,action_id,
      occurrence_no,step_no,period_no,place,recorded_by,note,victim_student_id,
      has_injury,has_damage,has_seizure,seizure_is_legal_matter)
  values (v_school,v_year,p_term,p_student,p_problem,v_action.id,v_count+1,v_step,p_period,p_place,
      p_by,p_note,p_victim,p_injury,p_damage,p_seizure,p_seizure_legal)
  returning id into v_rec;

  if not v_beyond then
    for it in select * from v2.fn_action_items_expanded(v_action.id) loop
      v_skip := false; v_why := null;
      if it.conditional and it.kind='repair' and not p_damage then v_skip:=true; v_why:='لا ينطبق: لا إتلاف في الواقعة'; end if;
      if it.conditional and it.kind='seize'  and not p_seizure then v_skip:=true; v_why:='لا ينطبق: لا مواد ممنوعة بحوزة الطالب'; end if;
      if it.kind='seize' and p_seizure and p_seizure_legal then
        v_skip:=true; v_why:='يُمنع الإتلاف: المضبوط مما ورد فيه نص نظامي — يُحال إلى مسار الجهات المختصة';
      end if;
      insert into v2.behavior_tasks(record_id,item_id,ord,kind,text_ar,owner_role,origin,status,skip_reason)
      values (v_rec,it.item_id,it.ord::smallint,it.kind,
        it.text_ar || case when it.from_step <> v_action.step_no
                      then ' [موروث من الإجراء '||it.from_step||' بنص: «جميع ما ذُكر في الإجراء السابق»]' else '' end,
        it.owner_role,it.origin,
        case when v_skip then 'skipped' when it.kind in ('deduct','compensation') then 'auto' else 'open' end,
        v_why);
    end loop;

    for un in select * from v2.conduct_universal
              where degree_no=v_prob.degree_no and stage_scope=v_prob.stage_scope
                and mode=v_prob.mode and target=v_prob.target order by item_no loop
      insert into v2.behavior_tasks(record_id,ord,kind,text_ar,owner_role,origin,status,skip_reason)
      values (v_rec,(90+un.item_no)::smallint,
        case when un.body_ar like '%1919%' then 'report_1919'
             when un.body_ar like '%الأمنية%' then 'police'
             when un.body_ar like '%الهلال الأحمر%' then 'red_crescent' else 'other' end,
        un.body_ar,'إدارة المدرسة','الدليل',
        case when un.body_ar like '%الهلال الأحمر%' and not p_injury then 'skipped' else 'open' end,
        case when un.body_ar like '%الهلال الأحمر%' and not p_injury then 'لا ينطبق: لا مصاب في الواقعة' else null end);
    end loop;
  end if;

  if not exists (select 1 from v2.behavior_ledger
                  where student_id=p_student and year_id=v_year and term_no=p_term and kind='opening') then
    select value_num into v_open from v2.conduct_rules where key='behavior.positive';
    insert into v2.behavior_ledger(school_id,year_id,term_no,student_id,kind,points,reason)
    values (v_school,v_year,p_term,p_student,'opening',v_open,
      'يُعدّ كل طالب مستحقًا لدرجة السلوك الإيجابي (80) درجة بشكل تلقائي في بداية كل فصل دراسي — م5 · CONDUCT-1447-OFF ص15');
  end if;

  if (not v_beyond) and coalesce(v_action.deducts_points,false) then
    select deduction into v_ded from v2.conduct_degrees where degree_no=v_prob.degree_no;
    insert into v2.behavior_ledger(school_id,year_id,term_no,student_id,kind,points,record_id,reason,by_person)
    values (v_school,v_year,p_term,p_student,'deduction',-v_ded,v_rec,
      'حسم '||v_ded||' درجة · الإجراء '||v_action.step_no||' من الدرجة '||v_prob.degree_no||
      ' · '||v_prob.text_ar||' · '||v_prob.source_doc||' '||v_prob.source_page, p_by);
  end if;

  return v_rec;
end $function$
;
