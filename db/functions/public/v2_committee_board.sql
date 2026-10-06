-- public.v2_committee_board(p_school uuid, p_committee text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 91cfdf1dd0e924f31958ac77eb930b78
CREATE OR REPLACE FUNCTION public.v2_committee_board(p_school uuid, p_committee text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb; rule jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  rule := v2.committee_rule(p_school,p_committee);
  select jsonb_build_object(
    'committee', (select jsonb_build_object('key',c.key,'label',c.label_ar,
        'purpose',c.purpose,'source',c.source_page,
        'mine',(c.school_id is not null),'active',c.is_active,
        'quorum',      rule->'quorum_min',
        'quorum_mode', rule->>'quorum_mode',
        'quorum_ar',   rule->>'quorum_ar',
        'seated',      rule->'seated',
        'allow_remote',rule->'allow_remote',
        'tie_rule',    rule->>'tie_rule',
        'quorum_note', coalesce(rule->>'note',
          'اجتهادُ مدرسةٍ — لا نصَّ للنصاب في الدليل التنظيميّ'))
      from v2.committees c where c.key=p_committee),
    'duties', (select coalesce(jsonb_agg(jsonb_build_object(
        'id',d.id,'ord',d.ord,'text',d.text_ar,'cadence',d.cadence,
        'source',d.source_ar,'mine',(d.school_id is not null)) order by d.ord),'[]'::jsonb)
      from v2.committee_duties d where d.committee_key=p_committee and d.is_active
        and (d.school_id is null or d.school_id=p_school)),
    'seats', (select jsonb_agg(jsonb_build_object(
        'ord',s.ord,'post',p.label_ar,'post_key',s.post_key,
        'role',s.seat_role,'role_ar',v2.seat_ar(s.seat_role),
        'count', case when s.post_key is null
                 then v2.seat_cap(p_school,p_committee,s.seat_role) else s.seat_count end,
        'count_guide', s.seat_count,
        'elected',s.is_elected,'elected_by',s.elected_by,
        'holders',(select coalesce(jsonb_agg(jsonb_build_object(
             'person',pe.id,'name',v2.fn_display_name(pe.full_name),
             'since',m.started_on,'nominated_by',m.nominated_by)),'[]'::jsonb)
           from v2.committee_members m join v2.people pe on pe.id=m.person_id
           where m.committee_key=p_committee and m.school_id=p_school
             and m.seat_role=s.seat_role and m.ended_on is null
             and (s.post_key is null or m.via_post_key=s.post_key))
      ) order by s.ord)
      from v2.committee_seats s left join v2.posts p on p.key=s.post_key
      where s.committee_key=p_committee),
    'my_seat', v2.seat_ar(v2.my_seat(p_school,p_committee))
  ) into r;
  return r;
end $function$
;
