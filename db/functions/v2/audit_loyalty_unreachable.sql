-- v2.audit_loyalty_unreachable()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8671bffb5783b68de44f26b7bb44ea8a
CREATE OR REPLACE FUNCTION v2.audit_loyalty_unreachable()
 RETURNS TABLE(obj text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  with live as (
    select a.school_id, array_agg(distinct a.post_key) as keys
      from v2.assignments a
     where a.started_on <= current_date
       and (a.ended_on is null or a.ended_on >= current_date)
     group by a.school_id)
  select 'مصدرُ نقاطٍ لا يملكه أحد · ' || s.title_ar,
         'المصدرُ مفتوحٌ ولا يحمل تكليفَه أحدٌ نافذٌ في المدرسة — وهو لـ: ' ||
           coalesce((select string_agg(coalesce(v2.role_ar(r), r), ' · ') from unnest(s.who_may) r), 'لا أحد'),
         'خلل'
    from v2.loyalty_sources s
    cross join live l
   where s.active and (s.school_id is null or s.school_id = l.school_id)
     and not (s.who_may && l.keys)
  union all
  select 'مكافأةٌ لا يصرفها أحد · ' || w.title_ar,
         case when w.needs_principal and not ('principal' = any (l.keys))
              then 'المكافأةُ تلزمها موافقةُ المدير ولا مديرَ نافذًا في المدرسة'
              else 'المكافأةُ معروضةٌ ولا يملك صرفَها أحدٌ نافذٌ — وهي لـ: ' ||
                   coalesce((select string_agg(coalesce(v2.role_ar(r), r), ' · ')
                               from unnest(w.who_may_spend) r), 'لا أحد') end,
         'خلل'
    from v2.loyalty_rewards w
    cross join live l
   where w.active and (w.school_id is null or w.school_id = l.school_id)
     and (not (w.who_may_spend && l.keys)
          or (w.needs_principal and not ('principal' = any (l.keys))));
$function$
;
