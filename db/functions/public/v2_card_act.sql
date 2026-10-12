-- public.v2_card_act(p_student uuid, p_kind text, p_code text, p_note text, p_place text, p_payload jsonb)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b3a201b6e88dad1042b467de7fb27e2a
CREATE OR REPLACE FUNCTION public.v2_card_act(p_student uuid, p_kind text, p_code text DEFAULT NULL::text, p_note text DEFAULT NULL::text, p_place text DEFAULT NULL::text, p_payload jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare g jsonb; sc uuid; me uuid; tm smallint; yr uuid;
        cp record; ev uuid; nm text; v_needs_window boolean;
        v_title text; v_pol text; sess uuid; n_steps int := 0;
        v_th int := null; v_td int := null; v_opd boolean := false;
        v_per smallint; v_sub text; v_eng jsonb; v_rid uuid; n int := null; v_cls uuid;
begin
  if p_kind in ('conduct','report_deputy') then
    raise exception 'المخالفةُ تُرصد في محرّك الدليل لا في البطاقة — وبابُها v2_record_behavior';
  end if;
  if p_kind = 'homework' then
    raise exception 'الواجبُ له ميدانُه — وبابُه v2_work_set، ويصل شاشةَ الطالب'; end if;
  if p_kind = 'exit' then
    raise exception 'الخروجُ له ميدانُه — وبابُه v2_exit_out، وعودتُه v2_exit_back'; end if;
  if p_kind = 'role' then
    raise exception 'الدورُ له ميدانُه — وبابُه v2_role_assign، وعزلُه v2_role_end'; end if;
  if p_kind not in ('practice','note') then
    raise exception 'نوعُ الفعل غير معروف'; end if;

  v_needs_window := p_kind = 'practice';

  g  := v2.card_gate(p_student, case p_kind
          when 'practice' then 'رصدَ ممارسةٍ في البطاقة'
          else 'كتابةَ ملاحظةٍ في البطاقة' end, v_needs_window);
  sc := (g->>'school')::uuid; me := (g->>'person')::uuid;
  tm := (g->>'term')::smallint; yr := nullif(g->>'year','')::uuid;
  v_per := ((g->'window')->>'period_no')::smallint;
  select v2.fn_display_name(full_name) into nm from v2.students where id=p_student;

  if v_per is not null then
    v_cls := v2.session_of(sc, me, current_date, v_per, null,
                           v2.rule_n(sc,'session_auto_open') = 1);
  end if;

  select id into sess from v2.card_sessions
   where student_id=p_student and person_id=me and on_date=current_date
   order by opened_at desc limit 1;

  if p_kind='practice' then
    select * into cp from v2.class_practices
     where code=p_code and active and (school_id is null or school_id=sc);
    if cp.code is null then raise exception 'ممارسةٌ غير معروفة'; end if;
    v_th := cp.threshold_count; v_td := cp.threshold_days; v_opd := coalesce(cp.once_per_day,false);
    if v_opd and exists (select 1 from v2.card_events ce
        where ce.student_id=p_student and ce.code=p_code and ce.kind='practice'
          and ce.on_date=current_date and ce.undone_at is null) then
      raise exception 'رُصدت عليه اليومَ — لا تُكرَّر · فتكرارُها يعاقبه مرارًا على غفلةٍ واحدة';
    end if;
    v_title := cp.title_ar; v_pol := cp.polarity;
    select e.subject_ar into v_sub from v2.effective_periods(sc, me, current_date) e
     where e.period_no = v_per limit 1;
    p_payload := p_payload || jsonb_build_object('points',cp.points,
      'grade_impact',cp.kind,'scope',cp.scope,
      'threshold_count',v_th,'threshold_days',v_td);
  else
    v_title := 'ملاحظة'; v_pol := 'neutral';
  end if;

  insert into v2.card_events(session_id,class_session,school_id,year_id,term_no,student_id,person_id,
      by_role_ar,on_date,period_no,slot_id,kind,code,title_ar,polarity,payload,note_ar,place_ar,is_test)
  values (sess,v_cls,sc,yr,tm,p_student,me,v2.role_ar(v2.my_role()),current_date,
      v_per, nullif((g->'window')->>'slot','')::uuid,
      p_kind,p_code,v_title,v_pol,p_payload,
      nullif(btrim(coalesce(p_note,'')),''), nullif(btrim(coalesce(p_place,'')),''),
      coalesce((select test_mode from v2.schools where id=sc),false))
  returning id into ev;

  if p_kind='practice' then
    v_eng := v2.fn_record_practice(p_student, p_code, v_per, v_sub, p_note, me);
    v_rid := (v_eng->>'record_id')::uuid;
    update v2.card_events
       set linked_target='practice_records', linked_id=v_rid, linked_at=now(),
           link_note='رُفع في اللحظة نفسِها'
     where id=ev;
    n := (v_eng->>'count_so_far')::int;
  end if;

  if v_pol = 'negative' then n_steps := v2.card_due_refresh(p_student); end if;

  return jsonb_build_object('ok',true,'event',ev,'kind',p_kind,'title_ar',v_title,
    'class_session', v_cls,
    'linked', v_rid is not null, 'record_id', v_rid,
    'count_so_far',n,'threshold',v_th,
    'reached', (n is not null and v_th is not null and n >= v_th),
    'points_awarded', coalesce((v_eng->>'points')::numeric, 0),
    'escalated', coalesce((v_eng->>'escalated')::boolean,false),
    'escalated_record', v_eng->>'escalated_record',
    'steps_due', n_steps,
    'summary_ar', case p_kind
      when 'practice' then (case when v_pol='positive' then 'سُجّلت إيجابيّةٌ لـ' else 'سُجّلت على ' end)||coalesce(nm,'الطالب')||' — «'||v_title||'»'
      else 'سُجّلت ملاحظة' end,
    'note_ar', case
      when coalesce((v_eng->>'escalated')::boolean,false)
        then 'وبلغت حدَّها فصُعِّدت آليًّا إلى الدليل — والسلّمُ يتولّاها من هناك'
      when n_steps > 0
        then 'وبلغت عتبةً — فصارت عليك خطوةٌ لها موعدٌ في «ما يُنتظر منّي»'
      when v_rid is not null
        then 'ورُفعت إلى سجلّ الممارسات في اللحظة نفسِها — فأثرُها في درجة المادّة قائم'
      else null end);
end $function$
;
