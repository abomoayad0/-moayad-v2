-- public.v2_plan_weeks(p_school uuid, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 819df7a60408f5e385ba14b87ecd3471
CREATE OR REPLACE FUNCTION public.v2_plan_weeks(p_school uuid, p_term smallint DEFAULT NULL::smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_scope text; v_rows jsonb; v_n int; v_exam int; v_cust int;
begin
  perform v2.assert_my_school(p_school,'قراءةَ أسابيع التوزيع');

  select s.calendar_scope into v_scope from v2.schools s where s.id=p_school;
  if v_scope is null then
    raise exception 'مسارُ التقويم غيرُ محدَّدٍ لمدرستك — ولا تُعرف أسابيعُ التوزيع حتى يُحدَّد';
  end if;
  if not exists (select 1 from v2.school_weeks(p_school)) then
    raise exception 'لا أسابيعَ منزَّلةٌ لمسار مدرستك — فلا يُحسب عليه توزيع';
  end if;

  select count(*) filter (where not w.is_exam), count(*) filter (where w.is_exam),
         count(*) filter (where w.is_custom)
    into v_n, v_exam, v_cust
    from v2.school_weeks(p_school) w
   where (p_term is null or w.term_no = p_term);

  select coalesce(jsonb_agg(jsonb_build_object(
           'term_no',w.term_no,'week_no',w.week_no,
           'from_h',w.from_h,'to_h',w.to_h,'from_g',w.from_g,'to_g',w.to_g,
           'study_days',(select count(*) from v2.calendar_days d
                          where d.week_id=w.week_id and d.day_kind='study'),
           'holidays',(select coalesce(jsonb_agg(distinct h.title_ar),'[]'::jsonb)
                         from v2.calendar_days d
                         join v2.calendar_holidays h on h.id=d.holiday_id
                        where d.week_id=w.week_id),
           'is_current',(current_date between w.from_g and w.to_g),
           'is_custom',w.is_custom
         ) order by w.term_no, w.week_no),'[]'::jsonb)
    into v_rows
    from v2.school_weeks(p_school) w
   where not w.is_exam and (p_term is null or w.term_no = p_term);

  return jsonb_build_object('weeks',v_rows,'count',v_n,'exam_weeks_n',v_exam,
    'custom_n',v_cust,'term_no',p_term,
    'summary_ar', v2.ar_count(v_n,'أسبوعٌ واحدٌ للتوزيع','أسبوعان للتوزيع',
                    'أسابيعَ للتوزيع','أسبوعًا للتوزيع')
      ||case when v_exam>0 then ' — و'||v2.ar_count(v_exam,'أسبوعُ اختبارٍ واحدٍ خارجَها',
               'أسبوعا اختبارٍ خارجَها','أسابيعِ اختبارٍ خارجَها','أسبوعَ اختبارٍ خارجَها')
             else '' end
      ||case when v_cust>0 then ' · ومنها '||v2.ar_count(v_cust,'أسبوعٌ مخصَّصٌ لمدرستك',
               'أسبوعان مخصَّصان لمدرستك','أسابيعَ مخصَّصةٍ لمدرستك','أسبوعًا مخصَّصًا لمدرستك')
             else '' end,
    'note_ar','أسبوعُ الاختبار لا يدخل في توزيع المنهج — فالمنهجُ ينتهي قبله. '
              ||'وأيّامُ الدراسة محسوبةٌ بعد خصم الإجازات. '
              ||'والأسبوعُ المخصَّصُ لمدرستك يُحسب بتاريخه المخصَّص لا بالأصل.');
end $function$
;
