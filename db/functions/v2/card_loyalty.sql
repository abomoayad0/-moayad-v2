-- v2.card_loyalty(p_school uuid, p_student uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e9d964b55572d06ba84914e275d219ba
CREATE OR REPLACE FUNCTION v2.card_loyalty(p_school uuid, p_student uuid, p_date date)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
begin
  return jsonb_build_object(
    'balance', v2.loyalty_balance(p_school, p_student),
    'balance_ar', v2.ar_balance(v2.loyalty_balance(p_school, p_student)),
    'can_grant', coalesce((
       select jsonb_agg(jsonb_build_object(
           'code', x.code, 'title_ar', x.title_ar, 'kind', x.kind, 'points', x.points,
           'points_ar', case when x.kind='earn'
               then 'تُضيف '||v2.ar_count(x.points,'نقطةً واحدة','نقطتين','نقاط','نقطة')
               else 'تُنقص '||v2.ar_count(x.points,'نقطةً واحدة','نقطتين','نقاط','نقطة') end,
           'needs_note', x.needs_note
               or (x.kind='deduct' and v2.rule_n(p_school,'loyalty_deduct_needs_note')=1),
           'week_left', coalesce(x.week_cap, v2.rule_n(p_school,'loyalty_week_cap_default'))
                        - v2.loyalty_week_used(p_school, p_student, x.code, p_date),
           'week_left_ar', v2.ar_left(
               coalesce(x.week_cap, v2.rule_n(p_school,'loyalty_week_cap_default'))
               - v2.loyalty_week_used(p_school, p_student, x.code, p_date)))
         order by x.kind desc, x.ord)
       from (select distinct on (code) * from v2.loyalty_sources
              where active and (school_id = p_school or school_id is null)
                and auto_kind = 'manual'
              order by code, (school_id is null)) x
       where v2.loyalty_can(x.who_may)), '[]'::jsonb),
    'auto_ar','وما كان آليًّا لا يُعرض زرُّه — تمنحه محرّكاتُه في موضعها');
end $function$
;
