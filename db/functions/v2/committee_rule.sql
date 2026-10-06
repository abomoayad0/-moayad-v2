-- v2.committee_rule(p_school uuid, p_committee text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f48dfd3fc462c40f08b904ff96fee40a
CREATE OR REPLACE FUNCTION v2.committee_rule(p_school uuid, p_committee text)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select jsonb_build_object(
    'quorum_min',   (select r.quorum_min   from v2.committee_school_rules r
                      where r.school_id=p_school and r.committee_key=p_committee and r.seat_role=''),
    'allow_remote', coalesce((select r.allow_remote from v2.committee_school_rules r
                      where r.school_id=p_school and r.committee_key=p_committee and r.seat_role=''), true),
    'tie_rule',     coalesce((select r.tie_rule from v2.committee_school_rules r
                      where r.school_id=p_school and r.committee_key=p_committee and r.seat_role=''), 'رئيس'),
    'note',         (select r.reason_ar from v2.committee_school_rules r
                      where r.school_id=p_school and r.committee_key=p_committee and r.seat_role=''));
$function$
;
