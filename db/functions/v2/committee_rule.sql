-- v2.committee_rule(p_school uuid, p_committee text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c2817cb2652a48f5c9254456a8831f8a
CREATE OR REPLACE FUNCTION v2.committee_rule(p_school uuid, p_committee text)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  with r as (select * from v2.committee_school_rules
              where school_id=p_school and committee_key=p_committee and seat_role=''),
  seated as (select count(*) n from v2.committee_members m
              where m.committee_key=p_committee and m.school_id=p_school and m.ended_on is null)
  select jsonb_build_object(
    'quorum_mode',  coalesce((select quorum_mode from r),'majority'),
    'quorum_min',   case coalesce((select quorum_mode from r),'majority')
                      when 'fixed' then (select quorum_min from r)
                      when 'none'  then null
                      else floor((select n from seated)/2.0)::int + 1 end,
    'seated',       (select n from seated),
    'quorum_ar',    case coalesce((select quorum_mode from r),'majority')
                      when 'fixed' then 'عددٌ ثابتٌ تضبطه المدرسة'
                      when 'none'  then 'بلا نصاب'
                      else 'فوق النصف من الأعضاء ('||
                           (floor((select n from seated)/2.0)::int + 1)||' من '||
                           (select n from seated)||')' end,
    'allow_remote', coalesce((select allow_remote from r), true),
    'tie_rule',     coalesce((select tie_rule from r), 'رئيس'),
    'note',         (select reason_ar from r));
$function$
;
