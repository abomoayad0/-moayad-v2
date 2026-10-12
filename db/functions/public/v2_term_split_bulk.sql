-- public.v2_term_split_bulk(p_grade smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c04c4a3fb2c7aa1953ba7db4aedaf759
CREATE OR REPLACE FUNCTION public.v2_term_split_bulk(p_grade smallint DEFAULT NULL::smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare
  r record; v_done int := 0; v_skip int := 0; v_rows jsonb := '[]'::jsonb;
  v_cum int; v_half numeric; v_best smallint; v_gap numeric; v_tot int; u record;
begin
  if not exists (select 1 from v2.app_users au
                  where au.id = auth.uid() and au.role = 'owner' and au.is_active) then
    raise exception 'الإقرارُ الجمليُّ لحدّ الفصلين لإدارة النظام وحدَها — فالحدُّ مرجعٌ مشتركٌ وزاريّ';
  end if;

  for r in
    select u.grade, u.subject_ar,
           coalesce(sum(coalesce(l.periods,1)),0) per_total
      from v2.curriculum_units u join v2.curriculum_lessons l on l.unit_id=u.id
     where (p_grade is null or u.grade=p_grade)
     group by u.grade, u.subject_ar
     order by u.grade, u.subject_ar
  loop
    if exists (select 1 from v2.curriculum_term_split s
                where s.grade=r.grade and s.subject_ar=r.subject_ar) then
      v_skip := v_skip + 1; continue;
    end if;

    v_tot := r.per_total; v_half := v_tot::numeric / 2;
    v_cum := 0; v_best := null; v_gap := null;
    for u in
      select x.unit_no,
             (select coalesce(sum(coalesce(l2.periods,1)),0)
                from v2.curriculum_lessons l2 where l2.unit_id=x.id) per
        from v2.curriculum_units x
       where x.grade=r.grade and x.subject_ar=r.subject_ar
       order by x.ord nulls last, x.unit_no nulls last
    loop
      v_cum := v_cum + u.per;
      if v_best is null or abs(v_cum - v_half) < v_gap then
        v_best := u.unit_no; v_gap := abs(v_cum - v_half);
      end if;
    end loop;

    if v_best is null then v_skip := v_skip + 1; continue; end if;

    update v2.curriculum_units u2
       set term_no = case when u2.unit_no <= v_best then 1 else 2 end
     where u2.grade=r.grade and u2.subject_ar=r.subject_ar;

    insert into v2.curriculum_term_split (grade, subject_ar, term1_until_unit,
        periods_t1, periods_t2, source_ar, note_ar, set_by, set_at)
    select r.grade, r.subject_ar, v_best,
           coalesce(sum(coalesce(l.periods,1)) filter (where u3.term_no=1),0),
           coalesce(sum(coalesce(l.periods,1)) filter (where u3.term_no=2),0),
           'اجتهادُ إدارة النظام — ينتظر مقابلةَ وثيقةٍ رسميّة',
           'قُسِم عند أقربِ حدّ وحدةٍ إلى نصف حصص المنهج. ولا وثيقةَ توزيعٍ على الفصلين عندنا، وكتبُ المنهج كلُّها موسومةٌ «الفصلُ الأوّل» في المصدر.',
           v2.current_person(), now()
      from v2.curriculum_units u3 join v2.curriculum_lessons l on l.unit_id=u3.id
     where u3.grade=r.grade and u3.subject_ar=r.subject_ar
    on conflict (grade, subject_ar) do nothing;

    v_done := v_done + 1;
    if v_done <= 8 then
      v_rows := v_rows || jsonb_build_object('grade',r.grade,'subject_ar',r.subject_ar,
        'until_unit',v_best,'periods_total',v_tot);
    end if;
  end loop;

  return jsonb_build_object('ok',true,'declared',v_done,'skipped',v_skip,'sample',v_rows,
    'summary_ar','أُقرّ حدُّ الفصلين لـ'||v_done||' مادّةً وصفًّا · وتُركت '||v_skip||' مُقرَّرةً من قبل',
    'note_ar','ومصدرُ كلٍّ مكتوبٌ «اجتهادُ إدارة النظام — ينتظر مقابلةَ وثيقةٍ رسميّة» — '
      ||'فلا يُحسب نصًّا وزاريًّا حتى يُقابَل. '
      ||'والقسمةُ عند أقربِ حدّ وحدةٍ إلى نصف الحصص، لا بسعة مدرسةٍ بعينها — فالحدُّ مشتركٌ. '
      ||'وللمدرسة بابُ اعتراضٍ بحجّتها، ويُصلح الحدُّ مرّةً للجميع.');
end $function$
;
