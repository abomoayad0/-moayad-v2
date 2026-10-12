-- v2.audit_exit_open()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 751596982c191412fe32abf40784fd24
CREATE OR REPLACE FUNCTION v2.audit_exit_open()
 RETURNS TABLE(obj text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select
    'خروجٌ بلا عودة · ' ||
      coalesce((select v2.fn_display_name(s.full_name) from v2.students s where s.id=x.student_id),'طالب')
      || ' · ' || x.to_where_ar,
    case when x.on_date < current_date
      then 'خرج في ' || x.on_date::text || ' ولم تُسجَّل عودتُه قطّ — فلا يُعرف أين انتهى به الأمر.'
      else 'خارجٌ منذ ' || v2.ar_num(greatest(0,(extract(epoch from (now()-x.out_at))/60)::int))
           || ' دقيقة، وحدُّ لوحة التحكّم '
           || v2.ar_num(v2.rule_n(x.school_id,'card_exit_minutes_warn')) || ' دقيقة.' end,
    'خلل'
  from v2.class_exits x
  where x.back_at is null
    and (x.on_date < current_date
         or (extract(epoch from (now()-x.out_at))/60)
            > (v2.rule_n(x.school_id,'card_exit_minutes_warn'))::int);
$function$
;
