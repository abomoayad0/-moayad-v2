-- public.v2_card_open(p_student uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 aed4f6c8dcaf9809c4308393bbb024d5
CREATE OR REPLACE FUNCTION public.v2_card_open(p_student uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; yr uuid; me uuid := v2.current_person();
        w jsonb; b text; sid uuid; nm text; grd smallint; sect text;
        v_dep int; r jsonb; v_days int;
begin
  if me is null then raise exception 'لا بدّ من تسجيل الدخول'; end if;
  select e.school_id, e.year_id, e.grade, e.section into sc, yr, grd, sect
    from v2.enrolments e where e.student_id=p_student and e.status='active' limit 1;
  if sc is null then raise exception 'الطالبُ لا قيدَ فعّالَ له'; end if;
  perform v2.assert_my_school(sc,'فتحَ بطاقة الطالب');
  select v2.fn_display_name(full_name) into nm from v2.students where id=p_student;

  b := v2.card_blocked(p_student, p_date);
  w := v2.card_window(sc, me, p_date);
  v_dep := v2.rule_n(sc,'card_deputy_reveal');
  v_days := (v2.rule_n(sc,'card_glance_days'))::int;

  insert into v2.card_sessions(school_id,student_id,person_id,on_date,period_no,
      slot_id,blocked_why,can_write,why_no_write,is_test)
  values (sc,p_student,me,p_date,(w->>'period_no')::smallint,
      nullif(w->>'slot','')::uuid, b, coalesce((w->>'can_write')::boolean,false) and b is null,
      coalesce(b, w->>'why_ar'), coalesce((select test_mode from v2.schools where id=sc),false))
  returning id into sid;

  r := jsonb_build_object(
    'session', sid,
    'student', jsonb_build_object('id',p_student,'name_ar',nm,
        'grade_ar', v2.grade_ar(grd), 'section', sect,
        'class_ar', v2.grade_ar(grd) || ' — ' || sect),
    'blocked_why', b,
    'window', w,
    'can_write', (coalesce((w->>'can_write')::boolean,false) and b is null),
    'tabs', (select jsonb_agg(t order by t->>'ord') from (
       select jsonb_build_object('key',k,'label_ar',l,'ord',o,
         'open', case
            when k in ('record','med') then true
            when b is not null then false
            when k in ('hw','fix','exit','role') then true
            else coalesce((w->>'can_write')::boolean,false) end,
         'why_ar', case
            when k in ('record','med') then null
            when b is not null then b
            when k in ('hw','fix','exit','role') then null
            when not coalesce((w->>'can_write')::boolean,false) then w->>'why_ar'
            else null end) t
       from (values
         ('laiha','اللائحة',1),('record','سجلّه',2),('med','صحّته',3),
         ('hw','كلّفه بواجب',4),('fix','تصحيح',5),('prac','ممارسات',6),
         ('pos','إيجابيات',7),('role','كلّفه بدور',8),('exit','خروجٌ مؤقّت',9),
         ('scatter','العتبة',10)
       ) v(k,l,o)) z),
    'laiha_from', jsonb_build_object(
       'why_ar','دليلُ السلوك محرّكُه قائمٌ ومكتمل — فالبطاقةُ تُحيل إليه ولا تنسخه · والممارساتُ منفصلةٌ عنه تمامًا لا تؤثّر فيه',
       'read', jsonb_build_array('v2_problems','v2_conduct_list','v2_student_tasks'),
       'write', jsonb_build_array('v2_record_behavior'),
       'owner_ar','ملكيّةُ كلِّ بندٍ منصوصةٌ في الدليل — والمعلّمُ يملك ١٢ بندًا بالنصّ'),
    'work_from', jsonb_build_object(
       'why_ar','الواجبُ ميدانٌ مستقلٌّ يصل شاشةَ الطالب',
       'read', jsonb_build_array('v2_work_of_student','v2_work_board','v2_work_kinds'),
       'write', jsonb_build_array('v2_work_set','v2_work_void')),
    'exit_from', jsonb_build_object(
       'why_ar','الخروجُ ميدانٌ له جدولُه — ولا يُكتب في أحداث البطاقة',
       'read', jsonb_build_array('v2_exit_of_student','v2_exit_now'),
       'write', jsonb_build_array('v2_exit_out','v2_exit_back'),
       'places', (select jsonb_agg(jsonb_build_object('key',k,'label_ar',v2.exit_where_ar(k)))
                   from (values ('restroom'),('counselor'),('deputy'),('principal'),
                                ('health'),('admin'),('activity'),('other')) q(k))),
    'health_from', jsonb_build_object(
       'why_ar','الصحّةُ ميدانُ الموجّه الصحّيّ — تُقرأ على انفرادٍ ويُسجَّل الاطّلاع، ولا تُكتب من البطاقة',
       'read', jsonb_build_array('v2_card_health'),
       'write', jsonb_build_array()),
    'roles_from', jsonb_build_object(
       'why_ar','الأدوارُ ميدانٌ له جدولُه — والقائمةُ من لوحة التحكّم لا من الشِّفرة',
       'read', jsonb_build_array('v2_roles_catalog','v2_roles_of_section','v2_roles_of_student'),
       'write', jsonb_build_array('v2_role_assign','v2_role_end')),
    'class_roles', public.v2_roles_catalog(sc),
    'roles_now', public.v2_roles_of_student(p_student),
    'loyalty_from', jsonb_build_object(
       'why_ar','نقاطُ الولاء محفظةٌ للطالب وحدَه بدفترِ حركاتٍ مستقلّ — تُكسب وتُخصم وتُصرف، ولا تُخلط بدرجةٍ ولا بدليل السلوك',
       'read', jsonb_build_array('v2_loyalty_catalog','v2_loyalty_wallet','v2_loyalty_of_section','v2_my_loyalty'),
       'write', jsonb_build_array('v2_loyalty_record','v2_loyalty_spend','v2_loyalty_undo')),
    'loyalty', v2.card_loyalty(sc, p_student, p_date),
    'task_due_days', jsonb_build_array(
        v2.rule_n(sc,'card_task_due_near'),
        v2.rule_n(sc,'card_task_due_mid'),
        v2.rule_n(sc,'card_task_due_far')),
    'glance', v2.card_glance(sc, p_student, p_date),
    'today', coalesce((select jsonb_agg(jsonb_build_object(
        'event',ce.id,'kind',ce.kind,'title_ar',ce.title_ar,'polarity',ce.polarity,
        'period',ce.period_no,'period_ar',v2.period_ar(ce.period_no),
        'by_ar',coalesce(v2.fn_display_name(pe.full_name),'—'),
        'code',ce.code) order by ce.created_at)
      from v2.card_events ce left join v2.people pe on pe.id=ce.person_id
      where ce.student_id=p_student and ce.on_date=p_date and ce.undone_at is null
        and ce.kind='practice'),'[]'::jsonb),
    'correctable', coalesce((select jsonb_agg(jsonb_build_object(
        'event',ce.id,'title_ar',ce.title_ar,'on_date',ce.on_date,
        'days_ago',(p_date - ce.on_date),
        'days_ago_ar', case when p_date = ce.on_date then 'اليومَ'
            else 'قبل '||v2.ar_count((p_date - ce.on_date),'يومٍ واحد','يومين','أيّام','يومًا') end,
        'state', v2.card_undo_state(ce.id))
        order by ce.created_at desc)
      from v2.card_events ce
      where ce.student_id=p_student and ce.undone_at is null
        and ce.kind='practice' and ce.on_date >= p_date - v_days),'[]'::jsonb),
    'practices', coalesce((select jsonb_agg(jsonb_build_object(
        'code',cp.code,'title_ar',cp.title_ar,'polarity',cp.polarity,
        'points', v2.practice_weight(sc, cp.code),
        'points_ar', case when v2.practice_weight(sc, cp.code) = 0 then 'بلا وزن'
            else v2.ar_num(v2.practice_weight(sc, cp.code)) end,
        'scope',cp.scope,'zone',cp.zone,'grade_impact',cp.kind,
        'once_per_day',cp.once_per_day,
        'threshold_count',cp.threshold_count,'threshold_days',cp.threshold_days,
        'threshold_ar', v2.threshold_ar(cp.threshold_count, cp.threshold_days),
        'done_today', exists (select 1 from v2.card_events ce
            where ce.student_id=p_student and ce.on_date=p_date
              and ce.kind='practice' and ce.code=cp.code and ce.undone_at is null))
        order by cp.polarity desc, cp.ord)
      from v2.class_practices cp
      where cp.active and (cp.school_id is null or cp.school_id=sc)),'[]'::jsonb),
    'practices_note_ar','الممارساتُ — إيجابيُّها وسالبُها — منفصلةٌ تمامًا عن دليل السلوك ولا تؤثّر فيه',
    'practice_balance', public.v2_practice_balance_of(p_student),
    'work', public.v2_work_of_student(p_student),
    'exits', public.v2_exit_of_student(p_student),
    'my_steps_here', coalesce((select jsonb_agg(jsonb_build_object(
        'step',ds.id,'title_ar',ds.title_ar,'due_on',ds.due_on,
        'due_ar', v2.fn_to_hijri(ds.due_on),
        'late',(ds.due_on < current_date),
        'late_ar', case when ds.due_on < current_date
            then 'تأخّرت '||v2.ar_count((current_date - ds.due_on),'يومًا واحدًا','يومين','أيّام','يومًا') end)
        order by ds.due_on)
      from v2.card_due_steps ds
      where ds.student_id=p_student and ds.owner_person=me and ds.answered_at is null),'[]'::jsonb),
    'deputy_reveal', v_dep,
    'note_ar', case when b is not null then 'الملفُّ للاطّلاع فقط — '||b
                    when not coalesce((w->>'can_write')::boolean,false) then w->>'why_ar'
                    else null end);
  return r;
end $function$
;
