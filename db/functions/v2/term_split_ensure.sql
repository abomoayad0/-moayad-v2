-- v2.term_split_ensure(p_grade smallint, p_subject text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4bb2889fbf7d45d070a8f0889c40ba85
CREATE OR REPLACE FUNCTION v2.term_split_ensure(p_grade smallint, p_subject text)
 RETURNS smallint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_mapped text[]; v_tot int; v_half numeric; v_cum int := 0;
        v_best smallint; v_gap numeric; u record; v_set smallint;
begin
  select term1_until_unit into v_set from v2.curriculum_term_split
   where grade=p_grade and subject_ar=btrim(p_subject);
  if v_set is not null then return v_set; end if;

  select array_agg(m.curriculum_subject_ar) into v_mapped
    from v2.curriculum_subject_map m where m.plan_subject_ar = btrim(p_subject);

  select coalesce(sum(coalesce(l.periods,1)),0) into v_tot
    from v2.curriculum_units u2 join v2.curriculum_lessons l on l.unit_id=u2.id
   where u2.grade=p_grade
     and (u2.subject_ar=btrim(p_subject) or u2.subject_ar = any(coalesce(v_mapped,'{}')));
  if v_tot = 0 then return null; end if;

  v_half := v_tot::numeric / 2;
  for u in
    select x.unit_no,
           (select coalesce(sum(coalesce(l2.periods,1)),0)
              from v2.curriculum_lessons l2 where l2.unit_id=x.id) per
      from v2.curriculum_units x
     where x.grade=p_grade
       and (x.subject_ar=btrim(p_subject) or x.subject_ar = any(coalesce(v_mapped,'{}')))
     order by x.ord nulls last, x.unit_no nulls last
  loop
    v_cum := v_cum + u.per;
    if v_best is null or abs(v_cum - v_half) < v_gap then
      v_best := u.unit_no; v_gap := abs(v_cum - v_half);
    end if;
  end loop;
  if v_best is null then return null; end if;

  update v2.curriculum_units u3
     set term_no = case when u3.unit_no <= v_best then 1 else 2 end
   where u3.grade=p_grade
     and (u3.subject_ar=btrim(p_subject) or u3.subject_ar = any(coalesce(v_mapped,'{}')));

  insert into v2.curriculum_term_split (grade, subject_ar, term1_until_unit,
      periods_t1, periods_t2, source_ar, note_ar)
  select p_grade, btrim(p_subject), v_best,
         coalesce(sum(coalesce(l.periods,1)) filter (where u4.term_no=1),0),
         coalesce(sum(coalesce(l.periods,1)) filter (where u4.term_no=2),0),
         'افتراضٌ آليّ',
         'قُسِم عند أقربِ حدّ وحدةٍ إلى نصف حصص المنهج — ولا وثيقةَ توزيعٍ على الفصلين عندنا. ويُصحّحه معلّمُ المادّة بإقراره.'
    from v2.curriculum_units u4 join v2.curriculum_lessons l on l.unit_id=u4.id
   where u4.grade=p_grade
     and (u4.subject_ar=btrim(p_subject) or u4.subject_ar = any(coalesce(v_mapped,'{}')))
  on conflict (grade, subject_ar) do nothing;

  return v_best;
end $function$
;
