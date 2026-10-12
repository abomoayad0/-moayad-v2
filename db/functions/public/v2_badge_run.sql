-- public.v2_badge_run(p_school uuid, p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6c81893933bc35bda854f58eff6dba71
CREATE OR REPLACE FUNCTION public.v2_badge_run(p_school uuid DEFAULT NULL::uuid, p_student uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; yr uuid; me uuid; lbl text; r record; bg v2.loyalty_badges;
        n_seen int := 0; n_given int := 0; names text[] := '{}';
begin
  me := v2.current_person();
  sc := coalesce(p_school,
                 (select s.school_id from v2.students s where s.id = p_student),
                 v2.acting_school());
  if sc is null then raise exception 'أيُّ مدرسة؟'; end if;
  perform v2.assert_my_school(sc, 'تشغيلَ محرّك الشارات');
  perform v2.assert_role(array['principal','deputy','deputy_students','deputy_school',
      'deputy_school_students','admin_assistant','admin_assistant_students','counselor'],
      'تشغيلَ محرّك الشارات');
  if p_student is not null then
    perform v2.assert_my_student(p_student, 'تشغيلَ محرّك الشارات');
  end if;

  select id into yr from v2.academic_years where school_id = sc and is_current limit 1;
  lbl := coalesce(v2.role_ar(v2.my_role()), 'بلا تكليف');

  for bg in
    select distinct on (b.code) b.*
      from v2.loyalty_badges b
     where b.active and b.rule_kind <> 'manual' and (b.school_id = sc or b.school_id is null)
     order by b.code, (b.school_id is null)
  loop
    for r in
      select e.student_id from v2.enrolments e
       where e.school_id = sc and e.status = 'active'
         and (p_student is null or e.student_id = p_student)
    loop
      if v2.badge_earned(sc, r.student_id, bg.code) then
        n_seen := n_seen + 1;
        if not exists (select 1 from v2.badge_awards w
                        where w.student_id = r.student_id and w.badge_code = bg.code
                          and w.year_id is not distinct from yr) then
          insert into v2.badge_awards
            (school_id, year_id, student_id, badge_code, awarded_on,
             by_person, by_role_ar, reason_ar, auto)
          values (sc, yr, r.student_id, bg.code, current_date, me, lbl,
                  v2.badge_rule_ar(sc, bg), true);
          n_given := n_given + 1;
        end if;
      end if;
    end loop;
    if not (bg.title_ar = any (names)) then names := names || bg.title_ar; end if;
  end loop;

  return jsonb_build_object(
    'school_id', sc,
    'badges_ar', case when coalesce(array_length(names,1),0) = 0
                      then 'لا شارةَ آليّةً مفتوحة'
                      else 'المحرّكُ نظر في: '||array_to_string(names,' · ') end,
    'eligible', n_seen,
    'given', n_given,
    'eligible_ar', case when n_seen = 0 then 'لا طالبَ استحقَّ شارةً آليّة'
      else 'استحقَّها '||v2.ar_count(n_seen,'طالبٌ واحد','طالبان','طلّاب','طالبًا') end,
    'given_ar', case when n_given = 0 then 'ولم تُمنح واحدةٌ — فكلُّ مستحقٍّ مُنح من قبل'
      else 'ومُنحت '||v2.ar_count(n_given,'شارةٌ واحدة','شارتان','شارات','شارة')||' الآن' end,
    'note_ar', 'لا تُمنح شارةٌ مرّتين في العام — يحرسه قيدٌ في القاعدة لا في الشاشة · '||
               'والمحرّكُ يُعاد نداؤه بلا أثرٍ مكرَّر');
end $function$
;
