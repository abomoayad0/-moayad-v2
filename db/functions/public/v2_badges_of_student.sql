-- public.v2_badges_of_student(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d7b367d14dd497119adf8fad454a651e
CREATE OR REPLACE FUNCTION public.v2_badges_of_student(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; yr uuid; got jsonb; ready jsonb; n int; m int;
begin
  perform v2.assert_my_student(p_student, 'شاراتِ الطالب');
  select school_id into sc from v2.students where id = p_student;
  if sc is null then raise exception 'لا طالبَ بهذا المعرّف'; end if;
  select id into yr from v2.academic_years where school_id = sc and is_current limit 1;

  select coalesce(jsonb_agg(jsonb_build_object(
           'badge_code', w.badge_code,
           'title_ar', coalesce(b.title_ar, w.badge_code),
           'note_ar', b.note_ar,
           'awarded_on', w.awarded_on,
           'awarded_on_ar', v2.fn_to_hijri(w.awarded_on),
           'auto', w.auto,
           'how_ar', case when w.auto then 'مُنحت آليًّا بشرطها'
                          else 'منحها '||coalesce(w.by_role_ar,'مُكلَّف') end,
           'reason_ar', w.reason_ar,
           'kept_ar', 'والشارةُ لا تُنزَع') order by w.awarded_on desc), '[]'::jsonb), count(*)
    into got, n
    from v2.badge_awards w
    left join lateral (select * from v2.badge_of(sc, w.badge_code)) b on true
   where w.student_id = p_student and (yr is null or w.year_id is not distinct from yr);

  with res as (
    select distinct on (b.code) b.*
      from v2.loyalty_badges b
     where b.active and b.rule_kind <> 'manual' and (b.school_id = sc or b.school_id is null)
     order by b.code, (b.school_id is null)
  )
  select coalesce(jsonb_agg(jsonb_build_object(
           'badge_code', r.code,
           'title_ar', r.title_ar,
           'rule_ar', v2.badge_rule_ar(sc, r::v2.loyalty_badges),
           'say_ar', 'استحقَّها ولم تُمنح بعد — تُمنح بتشغيل محرّكها')
           order by r.ord, r.code), '[]'::jsonb), count(*)
    into ready, m
    from res r
   where v2.badge_earned(sc, p_student, r.code)
     and not exists (select 1 from v2.badge_awards w
                      where w.student_id = p_student and w.badge_code = r.code
                        and w.year_id is not distinct from yr);

  return jsonb_build_object(
    'student_id', p_student,
    'rows', got,
    'count', n,
    'count_ar', case when n = 0 then 'لم تُمنح له شارةٌ في هذا العام'
      else 'له '||v2.ar_count(n,'شارةٌ واحدة','شارتان','شارات','شارة')||' في هذا العام' end,
    'ready', ready,
    'ready_count', m,
    'ready_ar', case when m = 0 then null
      else 'ويستحقُّ '||v2.ar_count(m,'شارةً واحدة','شارتين','شارات','شارة')||
           ' لم تُمنح بعد — بانتظار محرّكها' end,
    'note_ar', 'الشارةُ تكريمٌ لا تُنزَع · ولا تُمنح مرّتين في العام');
end $function$
;
