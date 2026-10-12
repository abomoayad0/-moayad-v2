-- public.v2_committee_rules_get(p_school uuid, p_committee text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9c4b30a10ab01d843e5edfd24d6ffe9a
CREATE OR REPLACE FUNCTION public.v2_committee_rules_get(p_school uuid, p_committee text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  if not v2.my_school(p_school) then raise exception '%', v2.not_my_school_ar(); end if;
  return v2.committee_rule(p_school, p_committee)
    || jsonb_build_object(
      'seat_count', v2.seat_cap(p_school,p_committee,'member'),
      'members', (select count(*) from v2.committee_members m
                   where m.committee_key=p_committee and m.school_id=p_school
                     and m.ended_on is null));
end $function$
;
