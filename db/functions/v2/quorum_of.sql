-- v2.quorum_of(p_school uuid, p_committee text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 395f8d5b5f1dc5785cdb78edcfc9b269
CREATE OR REPLACE FUNCTION v2.quorum_of(p_school uuid, p_committee text)
 RETURNS smallint
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select r.quorum_min from v2.committee_school_rules r
   where r.school_id=p_school and r.committee_key=p_committee and r.seat_role='';
$function$
;
