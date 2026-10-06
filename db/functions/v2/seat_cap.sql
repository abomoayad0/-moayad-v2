-- v2.seat_cap(p_school uuid, p_committee text, p_seat_role text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f459f8b331c5e07f6a9f004d3fc76c8a
CREATE OR REPLACE FUNCTION v2.seat_cap(p_school uuid, p_committee text, p_seat_role text)
 RETURNS smallint
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce(
    (select r.seat_count from v2.committee_school_rules r
      where r.school_id=p_school and r.committee_key=p_committee
        and r.seat_role=p_seat_role and r.seat_count is not null),
    (select s.seat_count from v2.committee_seats s
      where s.committee_key=p_committee and s.seat_role=p_seat_role
        and s.post_key is null limit 1));
$function$
;
