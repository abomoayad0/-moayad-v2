-- public.v2_committee_rules(p_school uuid, p_committee text, p_quorum smallint, p_allow_remote boolean, p_tie_rule text, p_note text, p_clear_quorum boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 fcb816bb21eb3550b1efbbe85acadb75
CREATE OR REPLACE FUNCTION public.v2_committee_rules(p_school uuid, p_committee text, p_quorum smallint, p_allow_remote boolean, p_tie_rule text, p_note text, p_clear_quorum boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare seats int;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy'],'ضبط قواعد اللجان');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if p_tie_rule is not null and p_tie_rule not in ('رئيس','تأجيل') then
    raise exception 'حكمُ التعادل: «رئيس» أو «تأجيل»'; end if;
  if p_quorum is not null then
    if p_quorum < 2 then raise exception 'لا ينعقد اجتماعٌ بأقلَّ من عضوين'; end if;
    select coalesce(sum(case when s.post_key is null
              then v2.seat_cap(p_school,p_committee,s.seat_role) else s.seat_count end),0)
      into seats from v2.committee_seats s where s.committee_key=p_committee;
    if p_quorum > seats then
      raise exception 'النصابُ (%) أكبرُ من مقاعد اللجنة في هذي المدرسة (%)', p_quorum, seats; end if;
  end if;

  insert into v2.committee_school_rules(school_id,committee_key,seat_role,
      quorum_min,allow_remote,tie_rule,reason_ar,set_by)
  values (p_school,p_committee,'',
      case when p_clear_quorum then null else p_quorum end,
      p_allow_remote,p_tie_rule,
      'اجتهادُ مدرسةٍ — لا نصَّ له في الدليل التنظيميّ'||
        case when btrim(coalesce(p_note,''))='' then '' else ' · '||btrim(p_note) end,
      v2.current_person())
  on conflict (school_id,committee_key,seat_role) do update set
      quorum_min   = case when p_clear_quorum then null
                          else coalesce(excluded.quorum_min, v2.committee_school_rules.quorum_min) end,
      allow_remote = coalesce(excluded.allow_remote, v2.committee_school_rules.allow_remote),
      tie_rule     = coalesce(excluded.tie_rule, v2.committee_school_rules.tie_rule),
      reason_ar    = excluded.reason_ar, set_by = excluded.set_by, set_at = now();
  return v2.committee_rule(p_school,p_committee);
end $function$
;
