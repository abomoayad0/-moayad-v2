-- v2.ladder_auto(p_record uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ae755a6e925600871665142b21ec2c6c
CREATE OR REPLACE FUNCTION v2.ladder_auto(p_record uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  r record; t record; did jsonb := '[]'::jsonb; nid uuid; d date; adv text;
  v_rules record; v_issue jsonb; v_time time; v_form smallint; v_comp jsonb;
begin
  select br.*, cp.text_ar ptext, cp.degree_no dno into r
    from v2.behavior_records br join v2.conduct_problems cp on cp.id=br.problem_id
   where br.id=p_record;
  if r.id is null then return did; end if;

  select * into v_rules from v2.conduct_school_rules where school_id = r.school_id;

  select a.text_ar into adv from v2.conduct_advice a
   where a.problem_id=r.problem_id and a.active
     and (a.school_id is null or a.school_id=r.school_id)
     and a.occurrence = least(r.occurrence_no,
          (select max(x.occurrence) from v2.conduct_advice x
            where x.problem_id=r.problem_id and x.active))
   order by (a.school_id is null) limit 1;
  if adv is not null then
    update v2.behavior_records set advice_ar=adv where id=p_record;
    did := did || jsonb_build_object('kind','advice','text',adv);
  end if;

  for t in select * from v2.behavior_tasks where record_id=p_record and status<>'done' loop
    nid := null; v_issue := null; v_form := null;

    if t.evidence_kind='auto' and t.kind='other' then
      update v2.behavior_tasks set status='done', done_at=now(), done_by=r.recorded_by,
        auto_note='وقع لحظةَ الرصد — فالتنبيهُ شفهيٌّ لا يُطلب إثباتُه'
       where id=t.id;
      did := did || jsonb_build_object('kind','notice','text',t.text_ar);

    elsif t.evidence_kind='services_review' then
      update v2.behavior_tasks set status='auto',
        auto_note='حالٌ مستمرّةٌ عند الموجّه الطلابيّ — لا فعلٌ ولا تأشير · تُعرض ولا تُطالَب'
       where id=t.id;
      did := did || jsonb_build_object('kind','services',
        'text','متابعةُ الموجّه حالٌ مستمرّةٌ — تُعرض ولا تُطالَب');

    -- ══ ③ التدوينُ في سجلّ المشكلات: فعلُ النظام · والتوقيعُ يبقى على الناس ══
    elsif t.kind='record_sign' then
      v_form := v2.form_for_kind('record_sign', r.school_id);
      if v_form is not null then
        v_issue := v2.fn_form_issue(v_form, r.student_id, r.id, t.id,
                     jsonb_build_object('on_date', current_date), r.recorded_by);
        if coalesce(v_issue->>'status','') = 'final' then
          update v2.behavior_tasks set
            auto_note='دُوّنت المشكلةُ في سجلّ المشكلات ('||
                      (select title_ar from v2.official_forms where form_no=v_form)||
                      ') — وبقي توقيعُ الطالب عليها'
           where id=t.id;
          did := did || jsonb_build_object('kind','register','entry',v_issue->>'entry',
            'text','دُوّن في سجلّ المشكلات — وبقي توقيعُ الطالب');
        else
          update v2.behavior_tasks set
            auto_note='لم يُدوَّن في سجلّ المشكلات بعد — '||coalesce(v_issue->>'why','')
           where id=t.id;
          did := did || jsonb_build_object('kind','register',
            'text','لم يُدوَّن بعد — '||coalesce(v_issue->>'why',''));
        end if;
      end if;

    -- ══ ② التعويضُ بنموذجه ══
    elsif t.kind='compensation' then
      v_comp := v2.fn_open_compensation(p_record);
      did := did || v_comp;
      v_form := v2.form_for_kind('compensation', r.school_id);
      if v_form is null then
        update v2.behavior_tasks set status='done', done_at=now(), done_by=r.recorded_by,
          auto_note='فُتحت فرصُ التعويض — ولم يُضبط نموذجُ التعويض في لوحة التحكّم'
         where id=t.id;
      else
        v_issue := v2.fn_form_issue(v_form, r.student_id, r.id, t.id,
                     jsonb_build_object('on_date', current_date), r.recorded_by);
        if (v_issue->>'ok')::boolean then
          update v2.behavior_tasks set status='done', done_at=now(), done_by=r.recorded_by,
            ev_on=current_date, ev_ref=(v_issue->>'entry'),
            auto_note='خرج نموذجُ فرص التعويض وسُلّم إلى الطالب ووليّ أمره — وله أن يتقدّم من صفحته'
           where id=t.id;
          did := did || jsonb_build_object('kind','comp_form','entry',v_issue->>'entry',
            'delivered',v_issue->>'delivered','text','خرج نموذجُ التعويض وسُلّم');
        else
          update v2.behavior_tasks set ev_ref=(v_issue->>'entry'),
            auto_note='فُتحت الفرصةُ ولم يخرج نموذجُها بعد — '||coalesce(v_issue->>'why','')||
                      ' · والمهمّةُ باقيةٌ حتى يخرج ويُسلَّم'
           where id=t.id;
          did := did || jsonb_build_object('kind','comp_form','status',v_issue->>'status',
            'text','لم يخرج نموذجُ التعويض — '||coalesce(v_issue->>'why',''));
        end if;
      end if;

    -- ══ ① الإحالةُ للموجّه بنموذجها السرّيّ ══
    elsif t.kind='counselor' then
      if not exists (select 1 from v2.counsel_cases c
                      where c.student_id=r.student_id and c.state='قيد المعالجة') then
        insert into v2.counsel_cases(school_id,student_id,record_id,problem_id,
            year_id,term_no,source_ar,state,opened_on,opened_by,is_test)
        values (r.school_id,r.student_id,r.id,r.problem_id,r.year_id,r.term_no,
            'إحالةٌ من الإجراء '||v2.ar_num(r.step_no)||' — '||r.ptext,
            'قيد المعالجة',current_date,r.recorded_by,
            coalesce((select test_mode from v2.schools where id=r.school_id),false))
        returning id into nid;
        did := did || jsonb_build_object('kind','counsel','case',nid,
          'text','فُتحت حالةٌ عند الموجّه الطلابيّ لدراستها');
      else
        did := did || jsonb_build_object('kind','counsel',
          'text','للطالب حالةٌ مفتوحةٌ عند الموجّه سلفًا — ولم تُفتح جديدة');
      end if;

      v_form := v2.form_for_kind('counselor', r.school_id);
      if v_form is null then
        update v2.behavior_tasks set
          auto_note='لم يخرج نموذجُ الإحالة — لم يُضبط في لوحة التحكّم · والمهمّةُ باقية'
         where id=t.id;
        did := did || jsonb_build_object('kind','refer_form',
          'text','لم يخرج نموذجُ الإحالة — لم يُضبط نموذجُه');
      else
        v_issue := v2.fn_form_issue(v_form, r.student_id, r.id, t.id,
                     jsonb_build_object('on_date', current_date), r.recorded_by);
        if (v_issue->>'ok')::boolean then
          update v2.behavior_tasks set status='done', done_at=now(), done_by=r.recorded_by,
            ev_on=current_date, ev_ref=(v_issue->>'entry'),
            auto_note='خرج نموذجُ الإحالة ('||
                      (select title_ar from v2.official_forms where form_no=v_form)||
                      ') وسُلّم إلى الموجّه الطلابيّ سرًّا · وتمامُ الدراسةِ عنده'
           where id=t.id;
          did := did || jsonb_build_object('kind','refer_form','entry',v_issue->>'entry',
            'delivered',v_issue->>'delivered',
            'text','خرج نموذجُ الإحالة وسُلّم إلى الموجّه سرًّا');
        else
          update v2.behavior_tasks set ev_ref=(v_issue->>'entry'),
            auto_note='لم يخرج نموذجُ الإحالة بعد — '||coalesce(v_issue->>'why','')||
                      ' · والمهمّةُ باقيةٌ حتى يخرج ويُسلَّم'
           where id=t.id;
          did := did || jsonb_build_object('kind','refer_form','status',v_issue->>'status',
            'missing',v_issue->'missing',
            'text','لم يخرج نموذجُ الإحالة — '||coalesce(v_issue->>'why',''));
        end if;
      end if;

    elsif t.kind='summon_guardian' and t.evidence_kind='auto' then
      d := v2.workdays_after(r.school_id, current_date,
             coalesce(v_rules.summon_after_workdays, 3));
      v_time  := v_rules.summon_time;
      v_form  := v2.form_for_kind('summon_guardian', r.school_id);

      if v_form is null then
        update v2.behavior_tasks set due_on=d,
          auto_note='لم يخرج خطابُ الدعوة — لم يُضبط نموذجُ الدعوة في لوحة التحكّم'
         where id=t.id;
        did := did || jsonb_build_object('kind','summon','due',d,
          'text','لم يخرج خطابُ الدعوة — لم يُضبط نموذجُه');
      else
        v_issue := v2.fn_form_issue(
          v_form, r.student_id, r.id, t.id,
          jsonb_strip_nulls(jsonb_build_object(
            'meet_on',   d,
            'meet_time', v_time,
            'purpose',   (select string_agg(x.text_ar, ' · ' order by x.ord)
                            from v2.behavior_tasks x where x.record_id = p_record))),
          r.recorded_by);

        if (v_issue->>'ok')::boolean then
          update v2.behavior_tasks set status='done', done_at=now(), done_by=r.recorded_by,
            ev_on=current_date, due_on=d, ev_ref=(v_issue->>'entry'),
            auto_note='خرج خطابُ الدعوة ('||
                      (select title_ar from v2.official_forms where form_no=v_form)||
                      ') وسُلّم إلى بوّابة وليّ الأمر · والموعدُ '||
                      coalesce(v2.fn_to_hijri(d)||' هـ','يُحدَّد')||
                      coalesce(' الساعة '||to_char(v_time,'HH24:MI'),'')
           where id=t.id;
          insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
              ref_table,ref_id,visible_to,needs_action,action_ar,is_test)
          values (r.school_id,'other',current_date,r.student_id,
              'دعوةٌ لمقابلة المدرسة',
              'نرجو حضوركم '||coalesce(v2.fn_to_hijri(d)||' هـ','في موعدٍ يُحدَّد')||
              coalesce(' الساعة '||to_char(v_time,'HH24:MI'),'')||
              ' — وخطابُ الدعوة في صندوق نماذجكم',
              'form_entries',(v_issue->>'entry')::uuid,'all',true,
              'أكّد حضورك أو اطلب تأجيلًا',
              coalesce((select test_mode from v2.schools where id=r.school_id),false));
          did := did || jsonb_build_object('kind','summon','due',d,
            'entry',v_issue->>'entry','delivered',v_issue->>'delivered',
            'text','خرج خطابُ الدعوة وسُلّم لوليّ الأمر');
        else
          update v2.behavior_tasks set due_on=d, ev_ref=(v_issue->>'entry'),
            auto_note='لم يخرج خطابُ الدعوة بعد — '||coalesce(v_issue->>'why','سببٌ غيرُ معروف')||
                      ' · والمهمّةُ باقيةٌ حتى يخرج ويُسلَّم'
           where id=t.id;
          did := did || jsonb_build_object('kind','summon','due',d,
            'entry',v_issue->>'entry','status',v_issue->>'status',
            'missing',v_issue->'missing',
            'text','لم يخرج خطابُ الدعوة — '||coalesce(v_issue->>'why',''));
        end if;
      end if;
    end if;
  end loop;
  return did;
end
$function$
;
