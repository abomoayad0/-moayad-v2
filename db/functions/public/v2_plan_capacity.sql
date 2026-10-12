-- public.v2_plan_capacity(p_school uuid, p_grade smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f0d38fcc36b9707d9d45e712e3b64440
CREATE OR REPLACE FUNCTION public.v2_plan_capacity(p_school uuid, p_grade smallint DEFAULT NULL::smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_rows jsonb; v_tight int := 0; v_short int := 0;
begin
  perform v2.assert_my_school(p_school,'فحصَ كفاية النصاب للمنهج');
  perform v2.assert_role(array['principal','deputy','deputy_academic','deputy_school',
    'admin_assistant','info_registrar'],'فحصَ كفاية النصاب للمنهج');

  with plan as (
    select sp.grade, sp.subject_ar, sp.slots
      from v2.subject_plan sp
     where sp.school_id=p_school and sp.active
       and (p_grade is null or sp.grade=p_grade)
  ), need as (
    select pl.grade, pl.subject_ar, pl.slots,
           (select coalesce(sum(coalesce(l.periods,1)),0)
              from v2.curriculum_units u
              join v2.curriculum_lessons l on l.unit_id=u.id
             where u.grade=pl.grade
               and (u.subject_ar = pl.subject_ar or u.subject_ar in
                     (select m.curriculum_subject_ar from v2.curriculum_subject_map m
                       where m.plan_subject_ar = pl.subject_ar))) as periods_need,
           (select count(*) from v2.school_weeks(p_school) x where not x.is_exam
             and x.week_no < coalesce((select min(y.week_no) from v2.school_weeks(p_school) y
                                        where y.term_no=x.term_no and y.is_exam), 99)) as plan_weeks
      from plan pl
  )
  select coalesce(jsonb_agg(jsonb_build_object(
           'grade',n.grade,'subject_ar',n.subject_ar,
           'weekly_slots',n.slots,'plan_weeks',n.plan_weeks,
           'capacity',n.slots*n.plan_weeks,'periods_need',n.periods_need,
           'slack',n.slots*n.plan_weeks - n.periods_need,
           'verdict_ar', case
             when n.periods_need = 0 then 'لا منهجَ منقولٌ لهذي المادّة'
             when n.slots*n.plan_weeks < n.periods_need then '🔴 النصابُ لا يكفي المنهج'
             when n.slots*n.plan_weeks - n.periods_need <= 5 then '🟠 فسحةٌ ضيّقةٌ — أيُّ تعطّلٍ يُفوّت المنهج'
             else '✅ كافٍ' end)
           order by (n.slots*n.plan_weeks - n.periods_need)),'[]'::jsonb),
         count(*) filter (where n.periods_need > 0 and n.slots*n.plan_weeks - n.periods_need between 1 and 5),
         count(*) filter (where n.periods_need > 0 and n.slots*n.plan_weeks < n.periods_need)
    into v_rows, v_tight, v_short
    from need n;

  return jsonb_build_object('rows',v_rows,'tight',v_tight,'short',v_short,
    'summary_ar', case when v_short > 0
        then '🔴 '||v2.ar_count(v_short,'مادّةٌ واحدةٌ نصابُها لا يكفي منهجَها',
               'مادّتان نصابُهما لا يكفي منهجَهما','موادَّ نصابُها لا يكفي منهجَها',
               'مادّةً نصابُها لا يكفي منهجَها')
        when v_tight > 0
        then '🟠 '||v2.ar_count(v_tight,'مادّةٌ واحدةٌ فسحتُها ضيّقة','مادّتان فسحتُهما ضيّقة',
               'موادَّ فسحتُها ضيّقة','مادّةً فسحتُها ضيّقة')
        else '✅ نصابُ كلّ مادّةٍ يكفي منهجَها' end,
    'note_ar','السعةُ = حصصُ المادّة أسبوعيًّا × أسابيعِ التوزيع (بلا أسبوع الاختبار). '
      ||'والفسحةُ = السعةُ ناقصَ ما يحتاجه المنهج. '
      ||'فمن ضاقت فسحتُه لا يُلام على تأخّرٍ لم يكن بيده — يُصلَح نصابُه قبل أن تبدأ السنة.');
end $function$
;
