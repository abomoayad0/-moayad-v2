-- public.v2_loyalty_catalog()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ed4f54ea3f6587aac66a92c92e551d22
CREATE OR REPLACE FUNCTION public.v2_loyalty_catalog()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid;
begin
  sc := v2.acting_school();
  if sc is null then raise exception 'لا مدرسةَ فعّالةٌ لك الآن'; end if;
  return jsonb_build_object(
    'sources', coalesce((
      select jsonb_agg(jsonb_build_object(
          'code', x.code, 'title_ar', x.title_ar, 'kind', x.kind, 'points', x.points,
          'points_ar', case when x.kind='earn'
              then 'تُضيف '||v2.ar_count(x.points,'نقطةً واحدة','نقطتين','نقاط','نقطة')
              else 'تُنقص '||v2.ar_count(x.points,'نقطةً واحدة','نقطتين','نقاط','نقطة') end,
          'week_cap', coalesce(x.week_cap, v2.rule_n(sc,'loyalty_week_cap_default')),
          'week_cap_ar', 'سقفُها الأسبوعيُّ '||v2.ar_count(
              coalesce(x.week_cap, v2.rule_n(sc,'loyalty_week_cap_default')),
              'نقطةٌ واحدة','نقطتان','نقاط','نقطة'),
          'needs_note', x.needs_note or (x.kind='deduct' and v2.rule_n(sc,'loyalty_deduct_needs_note')=1),
          'who_ar', (select string_agg(coalesce(v2.role_ar(r), r), ' · ') from unnest(x.who_may) r),
          'auto_kind', x.auto_kind,
          'auto_ar', case x.auto_kind
              when 'engine'  then 'تُمنح آليًّا — ولا تُطلب بيد'
              when 'blocked' then 'لا محرّكَ لها ولا تُمنح بيد'
              else 'تُمنح بيدِ من يملكها' end,
          'auto_note_ar', x.auto_note_ar,
          'can_i', x.auto_kind = 'manual' and v2.loyalty_can(x.who_may),
          'is_school', x.school_id is not null,
          'note_ar', x.note_ar) order by x.ord, x.title_ar)
      from (
        select distinct on (code) * from v2.loyalty_sources
         where active and (school_id = sc or school_id is null)
         order by code, (school_id is null)
      ) x), '[]'::jsonb),
    'rewards', coalesce((
      select jsonb_agg(jsonb_build_object(
          'code', y.code, 'title_ar', y.title_ar, 'price', y.price,
          'price_ar', 'بـ'||v2.ar_count(y.price,'نقطةٍ واحدة','نقطتين','نقاط','نقطة'),
          'needs_principal', y.needs_principal,
          'needs_principal_ar', case when y.needs_principal then 'تلزمها موافقةُ المدير' end,
          'stock', y.stock,
          'stock_ar', case when y.stock is null then 'بلا حدٍّ للعدد'
              else 'المتاحُ منها '||v2.ar_count(y.stock,'واحدةٌ','اثنتان','قطع','قطعة') end,
          'who_ar', (select string_agg(coalesce(v2.role_ar(r), r), ' · ') from unnest(y.who_may_spend) r),
          'can_i', v2.loyalty_can(y.who_may_spend)
                   and (not y.needs_principal or v2.loyalty_can(array['principal'])),
          'is_school', y.school_id is not null,
          'note_ar', y.note_ar) order by y.price, y.ord)
      from (
        select distinct on (code) * from v2.loyalty_rewards
         where active and (school_id = sc or school_id is null)
         order by code, (school_id is null)
      ) y), '[]'::jsonb),
    'engines_ar','المصادرُ الآليّة: الممارسةُ الإيجابيّةُ تُمنح في لحظة الرصد · والأسبوعُ التامُّ يُمنح بنداء v2_loyalty_week_run بعد انقضاء الأسبوع',
    'rules', jsonb_build_object(
      'allow_negative', v2.rule_n(sc,'loyalty_allow_negative') = 1,
      'max_per_act',    v2.rule_n(sc,'loyalty_max_per_act'),
      'week_cap',       v2.rule_n(sc,'loyalty_week_cap_default'),
      'undo_minutes',   v2.rule_n(sc,'loyalty_undo_minutes'),
      'spend_needs_balance', v2.rule_n(sc,'loyalty_spend_needs_balance') = 1),
    'rules_ar', concat_ws(' · ',
      case when v2.rule_n(sc,'loyalty_allow_negative') = 1
           then 'يُسمح برصيدٍ تحت الصفر' else 'ولا يهبط الرصيدُ تحت الصفر' end,
      'وأكبرُ ما يُمنح في الحركة '||v2.ar_count(v2.rule_n(sc,'loyalty_max_per_act'),'نقطةٌ واحدة','نقطتان','نقاط','نقطة'),
      'ومهلةُ التراجع '||v2.ar_count(v2.rule_n(sc,'loyalty_undo_minutes'),'دقيقةٌ واحدة','دقيقتان','دقائق','دقيقة')));
end $function$
;
