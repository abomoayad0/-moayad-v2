-- public.v2_practice_weights()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8580c4bc1d39c8c4e3cdc35ce2f4a75f
CREATE OR REPLACE FUNCTION public.v2_practice_weights()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid;
begin
  sc := v2.acting_school();
  if sc is null then raise exception 'لا مدرسةَ فعّالةٌ لك الآن'; end if;
  perform v2.assert_my_school(sc,'قراءةَ أوزان الممارسات');
  return jsonb_build_object(
    'rules', jsonb_build_object(
      'negative_weighed', v2.rule_n(sc,'practice_negative_weighed') = 1,
      'weight_max', (v2.rule_n(sc,'practice_weight_max_pct'))::numeric/100,
      'day_cap',    (v2.rule_n(sc,'practice_day_cap_pct'))::numeric/100),
    'rules_ar', concat_ws(' · ',
      case when v2.rule_n(sc,'practice_negative_weighed') = 1
           then 'السالبُ يُحسم من الرصيد' else 'السالبُ عتبةٌ ولا يُحسم من الرصيد' end,
      'وأكبرُ وزنٍ للحركة '||v2.ar_num((v2.rule_n(sc,'practice_weight_max_pct'))::numeric/100),
      'وسقفُ اليوم '||v2.ar_num((v2.rule_n(sc,'practice_day_cap_pct'))::numeric/100)),
    'rows', coalesce((
      select jsonb_agg(jsonb_build_object(
          'code', c.code, 'title_ar', c.title_ar, 'polarity', c.polarity,
          'catalogue_points', c.points,
          'points', v2.practice_weight(sc, c.code),
          'is_school', exists (select 1 from v2.practice_weights w
                                where w.school_id=sc and w.code=c.code and w.active),
          'day_cap', (select w.day_cap from v2.practice_weights w
                       where w.school_id=sc and w.code=c.code and w.active),
          'threshold_count', c.threshold_count, 'threshold_days', c.threshold_days,
          'weight_ar', case when v2.practice_weight(sc, c.code) = 0
              then 'بلا وزن' else v2.ar_num(v2.practice_weight(sc, c.code)) end,
          'effect_ar', case
              when v2.practice_weight(sc, c.code) = 0 then 'لا تمسُّ الرصيد'
              when c.polarity='negative' and v2.rule_n(sc,'practice_negative_weighed') <> 1
                then 'لا تُحسم — المفتاحُ مُطفأ'
              when c.polarity='positive' then 'تُضيف إلى الرصيد'
              else 'تُحسم من الرصيد' end)
        order by c.polarity desc, c.ord, c.title_ar)
      from v2.class_practices c
      where c.active and (c.school_id is null or c.school_id = sc)), '[]'::jsonb),
    'note_ar','أوزانُ الفهرس اجتهادٌ، ووزنُ المدرسةِ يُقدَّم عليه · والسالبُ أوزانُه صفرٌ في الفهرس حتى تضعها المدرسة');
end $function$
;
