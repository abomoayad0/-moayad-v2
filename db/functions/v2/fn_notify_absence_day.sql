-- v2.fn_notify_absence_day(p_student uuid, p_date date, p_by uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8270f2614b8e440d6798e774d70292b9
CREATE OR REPLACE FUNCTION v2.fn_notify_absence_day(p_student uuid, p_date date, p_by uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_school uuid; v_name text; v_ex boolean; v_due date; v_days numeric;
        v_ev uuid; v_id uuid; v_test boolean;
        msg text; st text; dt text; hn text; cx text;
begin
  select id into v_id from v2.absence_notices where student_id=p_student and on_date=p_date;
  if v_id is not null then return v_id; end if;        -- أُخطر في يومه سلفًا

  select e.school_id into v_school from v2.enrolments e
   where e.student_id=p_student and e.status='active' order by e.created_at desc limit 1;
  if v_school is null then return null; end if;

  select s.full_name into v_name from v2.students s where s.id=p_student;
  v_ex   := v2.fn_is_excused(p_student, p_date);
  v_test := coalesce((select test_mode from v2.schools where id=v_school), false);

  select value_num into v_days from v2.conduct_rules where key='excuse.window_days';
  v_due := v2.workdays_after(v_school, p_date, coalesce(v_days,3)::int);

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,needs_action,action_ar,is_test)
  values (v_school,'absence_report',p_date,p_student,
      'لم يحضر ابنكم اليوم',
      'نُخبركم أنّ ابنكم '||coalesce(v2.fn_display_name(v_name),'')||
      ' لم يحضر يومَ '||coalesce(v2.fn_to_hijri(p_date)||' هـ', p_date::text)||'. '||
      case when v_ex then 'وعذرُه مقبولٌ عندنا، ولا يُحسم على درجة مواظبته شيء.'
           else 'ولكم مهلةُ '||
                v2.ar_count(coalesce(v_days,3)::int,'يومِ عملٍ واحد','يومَي عمل',
                            'أيّامِ عمل','يومَ عمل')||
                ' لتقديم العذر — إلى '||coalesce(v2.fn_to_hijri(v_due)||' هـ', v_due::text)||
                '. وتقديمُ العذر المقبول لا يُؤثّر على درجة المواظبة.' end,
      'absence_notices',null,'all',
      case when v_ex then false else true end,
      case when v_ex then null else 'قدّم العذرَ أو أكّد علمك' end,
      v_test)
  returning id into v_ev;

  insert into v2.absence_notices(school_id,student_id,on_date,excused,excuse_due,
      event_id,by_person,is_test)
  values (v_school,p_student,p_date,v_ex,
      case when v_ex then null else v_due end, v_ev, coalesce(p_by, v2.current_person()), v_test)
  returning id into v_id;

  update v2.events set ref_id = v_id where id = v_ev;
  return v_id;
exception when others then
  get stacked diagnostics st=returned_sqlstate, msg=message_text, dt=pg_exception_detail,
    hn=pg_exception_hint, cx=pg_exception_context;
  perform v2.fn_log_error(msg,'fn_notify_absence_day','المواظبة','إخطارُ وليّ الأمر بالغياب',
    jsonb_build_object('student',p_student,'on_date',p_date),st,dt,hn,cx,'engine','error');
  return null;                        -- الإخطارُ لا يُسقط الرصدَ · ولكنّه يُكتب في سجلّ الأخطاء
end $function$
;
