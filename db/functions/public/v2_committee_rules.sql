-- public.v2_committee_rules(p_school uuid, p_committee text, p_quorum smallint, p_allow_remote boolean, p_tie_rule text, p_note text, p_quorum_mode text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4ae966339486c8de8fbe7379e10a60fc
CREATE OR REPLACE FUNCTION public.v2_committee_rules(p_school uuid, p_committee text, p_quorum smallint, p_allow_remote boolean, p_tie_rule text, p_note text, p_quorum_mode text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare seated int;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy'],'ضبط قواعد اللجان');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if p_tie_rule is not null and p_tie_rule not in ('رئيس','تأجيل') then
    raise exception 'حكمُ التعادل: «رئيس» أو «تأجيل»'; end if;
  if p_quorum_mode is not null and p_quorum_mode not in ('majority','fixed','none') then
    raise exception 'النصاب: «فوق النصف» أو «عددٌ ثابت» أو «بلا نصاب»'; end if;

  select count(*) into seated from v2.committee_members
   where committee_key=p_committee and school_id=p_school and ended_on is null;

  if p_quorum_mode = 'fixed' then
    if p_quorum is null then raise exception 'اكتب العددَ الثابت'; end if;
    if p_quorum < 2 then raise exception 'لا ينعقد اجتماعٌ بأقلَّ من عضوين'; end if;
    if p_quorum > seated then
      raise exception 'النصابُ (%) أكبرُ من أعضاء اللجنة في هذي المدرسة (%)', p_quorum, seated; end if;
  end if;

  insert into v2.committee_school_rules(school_id,committee_key,seat_role,
      quorum_mode,quorum_min,allow_remote,tie_rule,reason_ar,set_by)
  values (p_school,p_committee,'',
      coalesce(p_quorum_mode,'majority'),
      case when coalesce(p_quorum_mode,'majority')='fixed' then p_quorum else null end,
      p_allow_remote,p_tie_rule,
      'اجتهادُ مدرسةٍ — لا نصَّ له في الدليل التنظيميّ'||
        case when btrim(coalesce(p_note,''))='' then '' else ' · '||btrim(p_note) end,
      v2.current_person())
  on conflict (school_id,committee_key,seat_role) do update set
      quorum_mode  = coalesce(excluded.quorum_mode, v2.committee_school_rules.quorum_mode),
      quorum_min   = case when coalesce(excluded.quorum_mode,'majority')='fixed'
                          then excluded.quorum_min else null end,
      allow_remote = coalesce(excluded.allow_remote, v2.committee_school_rules.allow_remote),
      tie_rule     = coalesce(excluded.tie_rule, v2.committee_school_rules.tie_rule),
      reason_ar    = excluded.reason_ar, set_by = excluded.set_by, set_at = now();
  return v2.committee_rule(p_school,p_committee);
end $function$
;
