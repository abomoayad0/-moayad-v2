-- public.v2_term_split_confirm(p_school uuid, p_grade smallint, p_subject text, p_until_unit smallint, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c076d21adfba0de7f3b4250734f84a45
CREATE OR REPLACE FUNCTION public.v2_term_split_confirm(p_school uuid, p_grade smallint, p_subject text, p_until_unit smallint DEFAULT NULL::smallint, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_me uuid := v2.current_person(); v_cur smallint; v_src text;
        v_n int; v_mapped text[]; v_max smallint; v_new smallint; v_same boolean;
begin
  perform v2.assert_my_school(p_school,'إقرارَ حدّ الفصلين');
  begin
    perform v2.assert_role(array['principal','deputy','deputy_academic','deputy_school',
      'admin_assistant','info_registrar'],'إقرارَ حدّ الفصلين');
  exception when others then
    perform v2.assert_role(array['subject_teacher','sped_teacher','gifted_teacher'],
      'إقرارَ حدّ الفصلين');
    if not exists (select 1 from v2.teacher_subjects ts
                    where ts.school_id=p_school and ts.person_id=v_me
                      and ts.subject_ar=btrim(p_subject))
       and not exists (select 1 from v2.timetable t
                    where t.school_id=p_school and t.person_id=v_me
                      and t.subject_ar=btrim(p_subject)) then
      raise exception 'هذي المادّةُ غيرُ مُسندةٍ إليك — ويُقرّ حدَّها معلّمُها أو الإدارة';
    end if;
  end;

  perform v2.term_split_ensure(p_grade, btrim(p_subject));

  select term1_until_unit, source_ar, confirmed_n into v_cur, v_src, v_n
    from v2.curriculum_term_split where grade=p_grade and subject_ar=btrim(p_subject);
  if v_cur is null then
    raise exception 'لا منهجَ منقولٌ لمادّة «%» في الصفّ % — فلا حدَّ له', btrim(p_subject), p_grade;
  end if;

  select array_agg(m.curriculum_subject_ar) into v_mapped
    from v2.curriculum_subject_map m where m.plan_subject_ar = btrim(p_subject);
  select max(u.unit_no) into v_max from v2.curriculum_units u
   where u.grade=p_grade
     and (u.subject_ar=btrim(p_subject) or u.subject_ar = any(coalesce(v_mapped,'{}')));

  v_new := coalesce(p_until_unit, v_cur);
  if v_new < 1 or v_new >= v_max then
    raise exception 'حدُّ الفصل الأوّل بين الوحدة ١ والوحدة % — ولا يكون آخرَ وحدةٍ وإلّا خلا الفصلُ الثاني',
      v_max - 1;
  end if;
  v_same := (v_new = v_cur);

  if not v_same then
    update v2.curriculum_units u
       set term_no = case when u.unit_no <= v_new then 1 else 2 end
     where u.grade=p_grade
       and (u.subject_ar=btrim(p_subject) or u.subject_ar = any(coalesce(v_mapped,'{}')));
  end if;

  update v2.curriculum_term_split s
     set term1_until_unit = v_new,
         confirmed_n = case when v_same then s.confirmed_n + 1 else 1 end,
         source_ar = 'أقرّه معلّمُ المادّة',
         note_ar = coalesce(nullif(btrim(coalesce(p_note,'')),''), s.note_ar),
         set_by = v_me, set_at = now(),
         periods_t1 = (select coalesce(sum(coalesce(l.periods,1)),0)
                         from v2.curriculum_units u join v2.curriculum_lessons l on l.unit_id=u.id
                        where u.grade=p_grade and u.term_no=1
                          and (u.subject_ar=btrim(p_subject) or u.subject_ar = any(coalesce(v_mapped,'{}')))),
         periods_t2 = (select coalesce(sum(coalesce(l.periods,1)),0)
                         from v2.curriculum_units u join v2.curriculum_lessons l on l.unit_id=u.id
                        where u.grade=p_grade and u.term_no=2
                          and (u.subject_ar=btrim(p_subject) or u.subject_ar = any(coalesce(v_mapped,'{}'))))
   where s.grade=p_grade and s.subject_ar=btrim(p_subject);

  select confirmed_n into v_n from v2.curriculum_term_split
   where grade=p_grade and subject_ar=btrim(p_subject);

  return jsonb_build_object('ok',true,'until_unit',v_new,'was',v_cur,
    'confirmed_n',v_n,'max_unit',v_max,
    'summary_ar', case when v_same
      then 'أُقرّ حدُّ الفصلين كما هو — الفصلُ الأوّلُ ينتهي بالوحدة '||v_new
           ||' · وأقرّه '||v_n||' من المعلّمين'
      else 'صُحِّح حدُّ الفصلين — الفصلُ الأوّلُ ينتهي بالوحدة '||v_new||' (كان '||v_cur||')' end,
    'note_ar','وأنت صاحبُ الكتاب، فكلمتُك أعلى من افتراض النظام. '
      ||'ويُورَث هذا الحدُّ لكلّ مدرسةٍ تستعمل النظام، ويتصحّح بإقرار معلّميه.');
end $function$
;
