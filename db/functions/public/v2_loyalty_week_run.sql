-- public.v2_loyalty_week_run(p_school uuid, p_week_start date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5c9f0fd5c5ff5dd65e5eb9a5dd0b4145
CREATE OR REPLACE FUNCTION public.v2_loyalty_week_run(p_school uuid DEFAULT NULL::uuid, p_week_start date DEFAULT NULL::date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; ws date; we date; n_given int := 0; n_seen int := 0; g numeric; r record;
begin
  sc := coalesce(p_school, v2.acting_school());
  if sc is null then raise exception 'أيُّ مدرسة؟'; end if;
  perform v2.assert_my_school(sc,'منحَ نقاط الأسبوع التامّ');
  perform v2.assert_role(array['principal','deputy','deputy_students','deputy_school',
      'deputy_school_students','admin_assistant','admin_assistant_students'],
      'منحَ نقاط الأسبوع التامّ');

  ws := v2.loyalty_week_start(coalesce(p_week_start, current_date - 7));
  we := ws + 6;
  if we >= current_date then
    raise exception 'الأسبوعُ لم ينقضِ بعد — ولا يُمنح أسبوعٌ قبل تمامه (يبدأ %s وينتهي %s)',
      v2.fn_to_hijri(ws), v2.fn_to_hijri(we);
  end if;

  for r in
    select e.student_id
      from v2.enrolments e
     where e.school_id = sc and e.status = 'active'
       and exists (select 1 from v2.attendance a
                    where a.student_id = e.student_id and a.on_date between ws and we)
       and not exists (select 1 from v2.attendance a
                    where a.student_id = e.student_id and a.on_date between ws and we
                      and a.state in ('absent','late'))
  loop
    n_seen := n_seen + 1;
    g := v2.loyalty_auto(sc, r.student_id, 'attend_week', v2.current_person(),
          'أسبوعٌ تامٌّ بلا غيابٍ ولا تأخّر — '||v2.fn_to_hijri(ws)||' إلى '||v2.fn_to_hijri(we),
          null, ws);
    if g > 0 then n_given := n_given + 1; end if;
  end loop;

  return jsonb_build_object('week_start',ws,'week_end',we,
    'week_ar','من '||v2.fn_to_hijri(ws)||' إلى '||v2.fn_to_hijri(we),
    'eligible',n_seen,'given',n_given,
    'said_ar', case when n_seen = 0
      then 'لا طالبَ أتمَّ الأسبوعَ بلا غيابٍ ولا تأخّر — أو لا حضورَ مرصودٌ في هذا الأسبوع'
      else 'أتمَّ الأسبوعَ '||v2.ar_count(n_seen,'طالبٌ واحد','طالبان','طلّاب','طالبًا')||
           ' · ومُنح منهم '||v2.ar_num(n_given)||
           case when n_given < n_seen then ' — والباقي مُنح من قبل أو بلغ سقفَه' else '' end end,
    'note_ar','لا يُمنح أسبوعٌ مرّتين — يحرسه قيدٌ في القاعدة لا في الشاشة');
end $function$
;
