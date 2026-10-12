-- public.v2_term_split_set(p_grade smallint, p_subject text, p_until_unit smallint, p_note text, p_source text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2b5b1dc869647823558358622d5fe886
CREATE OR REPLACE FUNCTION public.v2_term_split_set(p_grade smallint, p_subject text, p_until_unit smallint, p_note text DEFAULT NULL::text, p_source text DEFAULT 'مُقرَّرٌ بأمر إدارة النظام'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_mapped text[]; v_p1 int; v_p2 int; v_n1 int; v_n2 int;
begin
  if not exists (select 1 from v2.app_users au
                  where au.id = auth.uid() and au.role = 'owner' and au.is_active) then
    raise exception 'حدُّ الفصلين مرجعٌ مشتركٌ لكلّ المدارس — ولا تُقرّره مدرسة. يُقرّه إدارةُ النظام.';
  end if;

  select array_agg(m.curriculum_subject_ar) into v_mapped
    from v2.curriculum_subject_map m where m.plan_subject_ar = btrim(p_subject);

  update v2.curriculum_units u
     set term_no = case when u.unit_no <= p_until_unit then 1 else 2 end
   where u.grade=p_grade
     and (u.subject_ar=btrim(p_subject) or u.subject_ar = any(coalesce(v_mapped,'{}')));

  select count(*) filter (where u.term_no=1), count(*) filter (where u.term_no=2),
         coalesce(sum(coalesce(l.periods,1)) filter (where u.term_no=1),0),
         coalesce(sum(coalesce(l.periods,1)) filter (where u.term_no=2),0)
    into v_n1, v_n2, v_p1, v_p2
    from v2.curriculum_units u join v2.curriculum_lessons l on l.unit_id=u.id
   where u.grade=p_grade
     and (u.subject_ar=btrim(p_subject) or u.subject_ar = any(coalesce(v_mapped,'{}')));

  insert into v2.curriculum_term_split (grade, subject_ar, term1_until_unit,
      periods_t1, periods_t2, source_ar, note_ar, set_by, set_at)
  values (p_grade, btrim(p_subject), p_until_unit, v_p1, v_p2,
          btrim(p_source), nullif(btrim(coalesce(p_note,'')),''), v2.current_person(), now())
  on conflict (grade, subject_ar) do update
    set term1_until_unit = excluded.term1_until_unit,
        periods_t1 = excluded.periods_t1, periods_t2 = excluded.periods_t2,
        source_ar = excluded.source_ar, note_ar = excluded.note_ar,
        set_by = excluded.set_by, set_at = now();

  return jsonb_build_object('ok',true,'grade',p_grade,'subject_ar',btrim(p_subject),
    'until_unit',p_until_unit,'units_t1',v_n1,'units_t2',v_n2,
    'periods_t1',v_p1,'periods_t2',v_p2,
    'summary_ar','أُقرّ حدُّ الفصلين لـ«'||btrim(p_subject)||'» الصفّ '||p_grade
      ||' — الفصلُ الأوّلُ ينتهي بالوحدة '||p_until_unit
      ||' ('||v_n1||' وحدةً · '||v_p1||' حصّة) والثاني ('||v_n2||' وحدةً · '||v_p2||' حصّة)',
    'note_ar','ويُورَث هذا الحدُّ لكلّ مدرسةٍ تستعمل النظام. ومصدرُه مُعلَنٌ: '||btrim(p_source));
end $function$
;
