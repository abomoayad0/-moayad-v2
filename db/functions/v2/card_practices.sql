-- v2.card_practices(p_school uuid, p_student uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9da50381ce7452b91461cb6b0c19818f
CREATE OR REPLACE FUNCTION v2.card_practices(p_school uuid, p_student uuid, p_date date)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
declare neg_on boolean;
begin
  neg_on := v2.rule_n(p_school,'practice_negative_weighed') = 1;
  return coalesce((select jsonb_agg(jsonb_build_object(
      'code',cp.code,'title_ar',cp.title_ar,'polarity',cp.polarity,
      'points', v2.practice_weight(p_school, cp.code),
      'points_ar', case
          when v2.practice_weight(p_school, cp.code) = 0 then 'بلا وزن'
          when cp.polarity = 'positive'
            then 'تُضيف '||v2.ar_num(v2.practice_weight(p_school, cp.code))||' إلى رصيد الممارسات'
          when not neg_on
            then 'وزنُها '||v2.ar_num(v2.practice_weight(p_school, cp.code))||
                 ' ولا تُحسم — مفتاحُ الحسم مُطفأٌ في لوحة التحكّم'
          else 'تُنقص '||v2.ar_num(v2.practice_weight(p_school, cp.code))||' من رصيد الممارسات' end,
      'scope',cp.scope,'zone',cp.zone,'grade_impact',cp.kind,
      'once_per_day',cp.once_per_day,
      'once_ar', case when cp.once_per_day then 'لا تُرصد أكثرَ من مرّةٍ في اليوم' else null end,
      'threshold_count',cp.threshold_count,'threshold_days',cp.threshold_days,
      'threshold_ar', v2.threshold_ar(cp.threshold_count, cp.threshold_days),
      'done_today', exists (select 1 from v2.card_events ce
          where ce.student_id=p_student and ce.on_date=p_date
            and ce.kind='practice' and ce.code=cp.code and ce.undone_at is null))
      order by cp.polarity desc, cp.ord)
    from v2.class_practices cp
    where cp.active and (cp.school_id is null or cp.school_id=p_school)),'[]'::jsonb);
end $function$
;
