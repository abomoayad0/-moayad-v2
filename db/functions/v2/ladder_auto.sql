-- v2.ladder_auto(p_record uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e5e091319c408410f2d01e9565a104e3
CREATE OR REPLACE FUNCTION v2.ladder_auto(p_record uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r record; t record; did jsonb := '[]'::jsonb; nid uuid; d date; adv text;
begin
  select br.*, cp.text_ar ptext, cp.degree_no dno into r
    from v2.behavior_records br join v2.conduct_problems cp on cp.id=br.problem_id
   where br.id=p_record;
  if r.id is null then return did; end if;

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
    if t.evidence_kind='auto' and t.kind='other' then
      update v2.behavior_tasks set status='done', done_at=now(), done_by=r.recorded_by,
        auto_note='وقع لحظةَ الرصد — فالتنبيهُ شفهيٌّ لا يُطلب إثباتُه'
       where id=t.id;
      did := did || jsonb_build_object('kind','notice','text',t.text_ar);

    elsif t.kind='compensation' then
      if not exists (select 1 from v2.merit_opportunities o
                      where o.school_id=r.school_id and o.state='مفتوحة') then
        insert into v2.merit_opportunities(school_id,merit_id,kind,title_ar,when_ar,
            capacity,state,held_by,is_test)
        select r.school_id, m.id, 'فرديّة', m.text_ar, 'متاحةٌ الآن', 30,
          'مفتوحة', r.recorded_by,
          coalesce((select test_mode from v2.schools where id=r.school_id),false)
         from v2.conduct_merits m where m.points=2 order by m.id limit 1
        returning id into nid;
        did := did || jsonb_build_object('kind','opportunity','opp',nid,
          'text','فُتحت فرصةُ تعويضٍ للطالب');
      end if;
      update v2.behavior_tasks set status='done', done_at=now(), done_by=r.recorded_by,
        auto_note='فُتحت للطالب فرصُ التعويض — وله أن يسجّل فيها'
       where id=t.id;

    elsif t.kind='counselor' and t.evidence_kind='auto' then
      if not exists (select 1 from v2.counsel_cases c
                      where c.student_id=r.student_id and c.state='قيد المعالجة') then
        insert into v2.counsel_cases(school_id,student_id,record_id,problem_id,
            year_id,term_no,source_ar,state,opened_on,opened_by,is_test)
        values (r.school_id,r.student_id,r.id,r.problem_id,r.year_id,r.term_no,
            'إحالةٌ آليّةٌ من الإجراء الثالث — '||r.ptext,'قيد المعالجة',current_date,r.recorded_by,
            coalesce((select test_mode from v2.schools where id=r.school_id),false))
        returning id into nid;
        did := did || jsonb_build_object('kind','counsel','case',nid,
          'text','أُحيل الملفُّ إلى الموجّه الطلابيّ لدراسة حالته');
      end if;
      update v2.behavior_tasks set status='done', done_at=now(), done_by=r.recorded_by,
        auto_note='أُحيل آليًّا إلى الموجّه — والدراسةُ عنده'
       where id=t.id;

    elsif t.kind='summon_guardian' and t.evidence_kind='auto' then
      d := v2.workdays_after(r.school_id, current_date, 3);
      update v2.behavior_tasks set status='done', done_at=now(), done_by=r.recorded_by,
        ev_on=current_date, due_on=d,
        auto_note='أُرسل خطابُ الدعوة (نموذج ١٠) إلى بوّابة وليّ الأمر · والموعدُ '||
                  coalesce(d::text,'يُحدَّد')
       where id=t.id;
      insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
          ref_table,ref_id,visible_to,needs_action,action_ar,is_test)
      values (r.school_id,'other',current_date,r.student_id,
          'دعوةٌ لمقابلة المدرسة',
          'نرجو حضوركم '||coalesce('يوم '||d::text,'في موعدٍ يُحدَّد')||
          ' لمناقشة خطّة تعديل سلوك ابنكم — نموذج ١٠',
          'behavior_records',r.id,'all',true,'أكّد حضورك أو اطلب تأجيلًا',
          coalesce((select test_mode from v2.schools where id=r.school_id),false));
      did := did || jsonb_build_object('kind','summon','due',d,
        'text','أُرسل خطابُ دعوة وليّ الأمر');
    end if;
  end loop;
  return did;
end $function$
;
