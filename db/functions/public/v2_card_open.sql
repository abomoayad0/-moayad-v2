-- public.v2_card_open(p_student uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e7a6551b1661fd0e31d611f981930388
CREATE OR REPLACE FUNCTION public.v2_card_open(p_student uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; yr uuid; me uuid := v2.current_person();
        w jsonb; b text; sid uuid; nm text; grd smallint; sect text;
        v_dep int; r jsonb;
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

  insert into v2.card_sessions(school_id,student_id,person_id,on_date,period_no,
      slot_id,blocked_why,can_write,why_no_write,is_test)
  values (sc,p_student,me,p_date,(w->>'period_no')::smallint,
      nullif(w->>'slot','')::uuid, b, coalesce((w->>'can_write')::boolean,false) and b is null,
      coalesce(b, w->>'why_ar'), coalesce((select test_mode from v2.schools where id=sc),false))
  returning id into sid;

  r := jsonb_build_object(
    'session', sid,
    'student', jsonb_build_object('id',p_student,'name_ar',nm,'grade',grd,'section',sect),
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
       'why_ar','دليلُ السلوك محرّكُه قائمٌ ومكتمل — فالبطاقةُ تُحيل إليه ولا تنسخه',
       'read', jsonb_build_array('v2_problems','v2_conduct_list','v2_student_tasks'),
       'write', jsonb_build_array('v2_record_behavior'),
       'owner_ar','ملكيّةُ كلِّ بندٍ منصوصةٌ في الدليل — والمعلّمُ يملك ١٢ بندًا بالنصّ'),
    'work_from', jsonb_build_object(
       'why_ar','الواجبُ ميدانٌ مستقلٌّ يصل شاشةَ الطالب',
       'read', jsonb_build_array('v2_work_of_student','v2_work_board'),
       'write', jsonb_build_array('v2_work_set','v2_work_void')),
    'exit_from', jsonb_build_object(
       'why_ar','الخروجُ ميدانٌ له جدولُه — ولا يُكتب في أحداث البطاقة',
       'read', jsonb_build_array('v2_exit_of_student','v2_exit_now'),
       'write', jsonb_build_array('v2_exit_out','v2_exit_back'),
       'places', (select jsonb_agg(jsonb_build_object('key',k,'label_ar',v2.exit_where_ar(k)))
                   from (values ('restroom'),('counselor'),('deputy'),('principal'),
                                ('health'),('admin'),('activity'),('other')) q(k))),
    'roles_from', jsonb_build_object(
       'why_ar','الأدوارُ ميدانٌ له جدولُه — والقائمةُ من لوحة التحكّم لا من الشِّفرة',
       'read', jsonb_build_array('v2_roles_catalog','v2_roles_of_section','v2_roles_of_student'),
       'write', jsonb_build_array('v2_role_assign','v2_role_end')),
    'class_roles', public.v2_roles_catalog(sc),
    'roles_now', public.v2_roles_of_student(p_student),
    'loyalty_from', jsonb_build_object(
       'why_ar','نقاطُ الولاء محفظةٌ للطالب وحدَه بدفترِ حركاتٍ مستقلّ — تُكسب وتُخصم وتُصرف، ولا تُخلط بدرجة السلوك ولا بفرص التعويض',
       'read', jsonb_build_array('v2_loyalty_catalog','v2_loyalty_wallet','v2_loyalty_of_section','v2_my_loyalty'),
       'write', jsonb_build_array('v2_loyalty_record','v2_loyalty_spend','v2_loyalty_undo')),
    'loyalty', jsonb_build_object(
       'balance', v2.loyalty_balance(sc, p_student),
       'balance_ar', v2.ar_count(v2.loyalty_balance(sc, p_student),
                                 'نقطةٌ واحدة','نقطتان','نقاط','نقطة'),
       'can_grant', coalesce((
          select jsonb_agg(jsonb_build_object(
              'code', x.code, 'title_ar', x.title_ar, 'kind', x.kind, 'points', x.points,
              'needs_note', x.needs_note or (x.kind='deduct' and v2.rule_n(sc,'loyalty_deduct_needs_note')=1),
              'week_left', coalesce(x.week_cap, v2.rule_n(sc,'loyalty_week_cap_default'))
                           - v2.loyalty_week_used(sc, p_student, x.code, p_date))
            order by x.kind desc, x.ord)
          from (select distinct on (code) * from v2.loyalty_sources
                 where active and (school_id = sc or school_id is null)
                 order by code, (school_id is null)) x
          where v2.loyalty_can(x.who_may)), '[]'::jsonb)),
    'task_due_days', jsonb_build_array(
        v2.rule_n(sc,'card_task_due_near'),
        v2.rule_n(sc,'card_task_due_mid'),
        v2.rule_n(sc,'card_task_due_far')),
    'glance', jsonb_build_object(
      'absent_days', (select count(*) from v2.attendance a
         where a.student_id=p_student and a.state='absent' and a.on_date >= p_date-30),
      'late_days', (select count(*) from v2.attendance a
         where a.student_id=p_student and a.state='late' and a.on_date >= p_date-30),
      'absent_periods', (select count(*) from v2.period_attendance pa
         where pa.student_id=p_student and pa.state='absent' and pa.on_date >= p_date-30),
      'exits_month', (select count(*) from v2.class_exits x
         where x.student_id=p_student and x.on_date >= p_date-30),
      'silent_days', (select (p_date - coalesce(max(ce.on_date), p_date-999))::int
         from v2.card_events ce where ce.student_id=p_student
           and ce.polarity='positive' and ce.undone_at is null),
      'silent_limit', v2.rule_n(sc,'card_silent_days')),
    'today', coalesce((select jsonb_agg(jsonb_build_object(
        'event',ce.id,'kind',ce.kind,'title_ar',ce.title_ar,'polarity',ce.polarity,
        'period',ce.period_no,'by_ar',coalesce(v2.fn_display_name(pe.full_name),'—'),
        'code',ce.code) order by ce.created_at)
      from v2.card_events ce left join v2.people pe on pe.id=ce.person_id
      where ce.student_id=p_student and ce.on_date=p_date and ce.undone_at is null
        and ce.kind='practice'),'[]'::jsonb),
    'correctable', coalesce((select jsonb_agg(jsonb_build_object(
        'event',ce.id,'title_ar',ce.title_ar,'on_date',ce.on_date,
        'days_ago',(p_date - ce.on_date),'state', v2.card_undo_state(ce.id))
        order by ce.created_at desc)
      from v2.card_events ce
      where ce.student_id=p_student and ce.undone_at is null
        and ce.kind='practice' and ce.on_date >= p_date - 30),'[]'::jsonb),
    'practices', coalesce((select jsonb_agg(jsonb_build_object(
        'code',cp.code,'title_ar',cp.title_ar,'polarity',cp.polarity,'points',cp.points,
        'scope',cp.scope,'zone',cp.zone,'grade_impact',cp.kind,
        'once_per_day',cp.once_per_day,
        'threshold_count',cp.threshold_count,'threshold_days',cp.threshold_days,
        'done_today', exists (select 1 from v2.card_events ce
            where ce.student_id=p_student and ce.on_date=p_date
              and ce.kind='practice' and ce.code=cp.code and ce.undone_at is null))
        order by cp.polarity desc, cp.ord)
      from v2.class_practices cp
      where cp.active and (cp.school_id is null or cp.school_id=sc)),'[]'::jsonb),
    'work', public.v2_work_of_student(p_student),
    'exits', public.v2_exit_of_student(p_student),
    'my_steps_here', coalesce((select jsonb_agg(jsonb_build_object(
        'step',ds.id,'title_ar',ds.title_ar,'due_on',ds.due_on,
        'late',(ds.due_on < current_date)) order by ds.due_on)
      from v2.card_due_steps ds
      where ds.student_id=p_student and ds.owner_person=me and ds.answered_at is null),'[]'::jsonb),
    'deputy_reveal', v_dep,
    'note_ar', case when b is not null then 'الملفُّ للاطّلاع فقط — '||b
                    when not coalesce((w->>'can_write')::boolean,false) then w->>'why_ar'
                    else null end);
  return r;
end $function$
;
