-- v2.badge_rule_ar(p_school uuid, b v2.loyalty_badges)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6323ddd777d850b967f486b050e2ed01
CREATE OR REPLACE FUNCTION v2.badge_rule_ar(p_school uuid, b v2.loyalty_badges)
 RETURNS text
 LANGUAGE plpgsql
 STABLE
AS $function$
declare d int;
begin
  if b.rule_kind = 'manual' then
    return case when b.rule_n is null
      then 'تُمنح بيدِ مُكلَّفٍ على شاهدٍ يراه'
      else 'تُمنح بيدِ مُكلَّفٍ على شاهدٍ يراه · والعددُ في وصفها ('||
           v2.ar_count(b.rule_n,'مرّةٌ واحدة','مرّتان','مرّات','مرّة')||
           ') لا تحرسه القاعدة — فالشاهدُ عند المُكلَّف' end;
  elsif b.rule_kind = 'no_late_month' then
    d := (v2.rule_n(p_school,'badge_no_late_days'))::int;
    return 'تُمنح آليًّا لمن لم يتأخّر في '||
           v2.ar_count(d,'يومٍ واحد','يومين','أيّام','يومًا')||
           ' مضت · ويلزمها حضورٌ مرصودٌ فيها';
  elsif b.rule_kind = 'distinct_sources' then
    return 'تُمنح آليًّا لمن كسب نقاطَ ولاءٍ من '||
           v2.ar_count(coalesce(b.rule_n,6),'مصدرٍ واحد','مصدرين','مصادرَ مختلفة','مصدرًا')||
           ' في هذا العام';
  elsif b.rule_kind = 'balance_at_least' then
    return 'تُمنح آليًّا لمن بلغ رصيدُ ولائه '||
           v2.ar_count(coalesce(b.rule_n,0),'نقطةً واحدة','نقطتين','نقاط','نقطة');
  end if;
  return 'شرطُها غيرُ معروفٍ في القاعدة';
end $function$
;
