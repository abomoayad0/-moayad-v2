-- v2.absence_task_auto(p_task uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 aa93b82c2c83dad06286cffc56e922a9
CREATE OR REPLACE FUNCTION v2.absence_task_auto(p_task uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare t record; v_rules record; v_form smallint; v_issue jsonb; d date; v_time time;
        v_case uuid; v_cite text;
begin
  select at.id, at.kind, at.text_ar, at.status, at.case_id,
         ac.student_id, ac.school_id, ac.year_id, ac.term_no, ac.excused, ac.days_count,
         al.article_no, al.source_page
    into t
    from v2.absence_tasks at
    join v2.absence_cases ac on ac.id = at.case_id
    join v2.absence_ladder al on al.id = ac.ladder_id
   where at.id = p_task;
  if t.id is null or t.status in ('done','skipped','refused') then return; end if;

  select * into v_rules from v2.conduct_school_rules where school_id = t.school_id;
  v_cite := 'م'||t.article_no||' '||t.source_page;

  if t.kind = 'counselor' then
    if not exists (select 1 from v2.counsel_cases c
                    where c.student_id=t.student_id and c.state='قيد المعالجة') then
      insert into v2.counsel_cases(school_id,student_id,problem_id,year_id,term_no,
          source_ar,state,opened_on,opened_by,is_test)
      values (t.school_id,t.student_id,null,t.year_id,t.term_no,
          'إحالةٌ من سلّم المواظبة — غيابٌ '||
          case when t.excused then 'بعذر' else 'بغير عذر' end||
          ' عند عتبة '||v2.ar_num(t.days_count)||' أيّام · '||v_cite,
          'قيد المعالجة',current_date,v2.current_person(),
          coalesce((select test_mode from v2.schools where id=t.school_id),false))
      returning id into v_case;
    end if;
    v_form := v2.form_for_kind('counselor', t.school_id);
    if v_form is null then
      update v2.absence_tasks set
        ev_text = 'لم يخرج نموذجُ الإحالة — لم يُضبط في لوحة التحكّم · والمهمّةُ باقية' where id=t.id;
    else
      v_issue := v2.fn_form_issue(v_form, t.student_id, null, t.id,
                   jsonb_build_object('on_date', current_date), v2.current_person());
      update v2.form_entries set case_id = t.case_id where task_id = t.id;
      if (v_issue->>'ok')::boolean then
        update v2.absence_tasks set status='done', done_at=now(), done_by=v2.current_person(),
            ev_on=current_date, ev_ref=(v_issue->>'entry'),
            ev_text='خرج نموذجُ الإحالة وسُلّم إلى الموجّه الطلابيّ سرًّا · وتمامُ الدراسة عنده'
         where id = t.id;
      else
        update v2.absence_tasks set ev_ref=(v_issue->>'entry'),
            ev_text='لم يخرج نموذجُ الإحالة بعد — '||coalesce(v_issue->>'why','')||
                    ' · والمهمّةُ باقيةٌ حتى يخرج ويُسلَّم' where id = t.id;
      end if;
    end if;

  elsif t.kind = 'summon_guardian' then
    d := v2.workdays_after(t.school_id, current_date, coalesce(v_rules.summon_after_workdays,3));
    v_time := v_rules.summon_time;
    v_form := v2.form_for_kind('summon_guardian', t.school_id);
    if v_form is null then
      update v2.absence_tasks set ev_on=d,
        ev_text='لم يخرج خطابُ الدعوة — لم يُضبط نموذجُ الدعوة في لوحة التحكّم' where id=t.id;
    else
      v_issue := v2.fn_form_issue(v_form, t.student_id, null, t.id,
        jsonb_strip_nulls(jsonb_build_object('meet_on',d,'meet_time',v_time,
          'purpose', t.text_ar)), v2.current_person());
      update v2.form_entries set case_id = t.case_id where task_id = t.id;
      if (v_issue->>'ok')::boolean then
        update v2.absence_tasks set status='done', done_at=now(), done_by=v2.current_person(),
            ev_on=current_date, ev_ref=(v_issue->>'entry'),
            ev_text='خرج خطابُ الدعوة وسُلّم إلى بوّابة وليّ الأمر · والموعدُ '||
                    coalesce(v2.fn_to_hijri(d)||' هـ','يُحدَّد')||
                    coalesce(' الساعة '||to_char(v_time,'HH24:MI'),'') where id = t.id;
        insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
            ref_table,ref_id,visible_to,needs_action,action_ar,is_test)
        values (t.school_id,'other',current_date,t.student_id,
            'دعوةٌ لمقابلة المدرسة — بشأن المواظبة',
            'نرجو حضوركم '||coalesce(v2.fn_to_hijri(d)||' هـ','في موعدٍ يُحدَّد')||
            coalesce(' الساعة '||to_char(v_time,'HH24:MI'),'')||
            ' — وخطابُ الدعوة في صندوق نماذجكم',
            'form_entries',(v_issue->>'entry')::uuid,'all',true,
            'أكّد حضورك أو اطلب تأجيلًا',
            coalesce((select test_mode from v2.schools where id=t.school_id),false));
      else
        update v2.absence_tasks set ev_on=d, ev_ref=(v_issue->>'entry'),
            ev_text='لم يخرج خطابُ الدعوة بعد — '||coalesce(v_issue->>'why','') where id = t.id;
      end if;
    end if;

  elsif t.kind = 'notify_guardian' then
    v_form := v2.form_for_kind('notify_guardian', t.school_id);
    if v_form is null then
      update v2.absence_tasks set ev_text='لم يخرج نموذجُ الإشعار — لم يُضبط في لوحة التحكّم'
       where id=t.id;
    else
      v_issue := v2.fn_form_issue(v_form, t.student_id, null, t.id,
                   jsonb_build_object('on_date', current_date), v2.current_person());
      update v2.form_entries set case_id = t.case_id where task_id = t.id;
      if (v_issue->>'ok')::boolean then
        update v2.absence_tasks set status='done', done_at=now(), done_by=v2.current_person(),
            ev_on=current_date, ev_ref=(v_issue->>'entry'),
            ev_text='خرج نموذجُ الإشعار وسُلّم إلى بوّابة وليّ الأمر' where id=t.id;
      else
        update v2.absence_tasks set ev_ref=(v_issue->>'entry'),
            ev_text='لم يخرج نموذجُ الإشعار بعد — '||coalesce(v_issue->>'why','') where id=t.id;
      end if;
    end if;

  elsif t.kind = 'warn_guardian' then
    insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
        ref_table,ref_id,visible_to,needs_action,action_ar,is_test)
    values (t.school_id,'other',current_date,t.student_id,
        'تنبيهٌ بشأن استمرار الغياب', t.text_ar||' · '||v_cite,
        'absence_tasks',t.id,'all',true,'أقرَّ بالاطّلاع',
        coalesce((select test_mode from v2.schools where id=t.school_id),false));
    update v2.absence_tasks set status='done', done_at=now(), done_by=v2.current_person(),
        ev_on=current_date,
        ev_text='سُلّم التنبيهُ في بوّابة وليّ الأمر — ولا نموذجَ رسميًّا له في الدليل، '||
                'فهو إشعارُ نظامٍ موثَّقٌ بتاريخه' where id = t.id;

  -- 🔑 الجلسةُ التوعويّة: دعوةٌ تُسلَّم، وإثباتٌ يُقفلها — ولا تُقفل بزرّ
  elsif t.kind = 'awareness_session' then
    insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
        ref_table,ref_id,visible_to,needs_action,action_ar,is_test)
    values (t.school_id,'other',current_date,t.student_id,
        'جلسةٌ توعويّةٌ بشأن المواظبة',
        t.text_ar||' · '||v_cite||' — وسيُحدَّد موعدُها معكم',
        'absence_tasks',t.id,'all',true,'تواصل مع المدرسة لتحديد الموعد',
        coalesce((select test_mode from v2.schools where id=t.school_id),false));
    update v2.absence_tasks set ev_on=current_date,
        ev_text='سُلّمت الدعوةُ إلى الجلسة في بوّابة وليّ الأمر — '||
                'ولا تُقفل الجلسةُ إلّا بإثباتِ عقدها (محضرٌ أو حضور)' where id = t.id;

  elsif t.kind in ('pledge','committee') then
    v_form := v2.form_for_kind(t.kind, t.school_id);
    if v_form is null then
      update v2.absence_tasks set ev_text='لم يخرج النموذجُ — لم يُضبط في لوحة التحكّم' where id=t.id;
    else
      v_issue := v2.fn_form_issue(v_form, t.student_id, null, t.id,
                   jsonb_build_object('on_date', current_date), v2.current_person());
      update v2.form_entries set case_id = t.case_id where task_id = t.id;
      update v2.absence_tasks set ev_on=current_date, ev_ref=(v_issue->>'entry'),
          ev_text = case when (v_issue->>'ok')::boolean
            then 'خرج النموذجُ وسُلّم — وبقي توقيعُ أصحابه'
            else 'لم يخرج النموذجُ بعد — '||coalesce(v_issue->>'why','') end
       where id = t.id;
    end if;

  elsif t.kind in ('assess_services','follow_up') then
    update v2.absence_tasks set is_standing = true,
        ev_text='حالٌ مستمرّةٌ عند الموجّه الطلابيّ — تُعرض ولا تُطالَب' where id=t.id;

  elsif t.kind = 'external_report' then
    update v2.absence_tasks set
        ev_text='يُرفع بخطابٍ صادرٍ إلى الجهات ذات الاختصاص ومعه إشعارُ إدارة التعليم · '||
                'ويُحمل على خطابٍ صادرٍ من سجلّ الصادر فيُقفل بخروجه · وإن كانت الحالةُ موسومةً بوقفِ التصعيد فلا يخرج (م35 بند 10)'
     where id = t.id;

  elsif t.kind = 'learning_plan' then
    update v2.absence_tasks set
        ev_text='يُكلَّف الطالبُ بخطّة التعلّم الأسبوعيّة والفصليّة — سواءٌ بعذرٍ أو بغيره (م35 بند 8) · '||
                'ولا نموذجَ لها في الدليل، فتُقفل بإثباتٍ يُرفَق' where id = t.id;

  -- 🔑 ونوعٌ لا يعرفه المحرّكُ يُعلَن ولا يُسكَت عنه
  else
    update v2.absence_tasks set
        ev_text='نوعُ هذا البند «'||t.kind||'» لا يعرفه محرّكُ المواظبة بعد — '||
                'فلا يخرج له ورقٌ آليًّا، ويُنفَّذ بالورق ويُقفل بإثباتٍ · '||
                'وهذا نقصٌ في النظام لا في الدليل'
     where id = t.id;
  end if;
end $function$
;
