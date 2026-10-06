-- public.v2_committee_board(p_school uuid, p_committee text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 afca3a0595f2d737a39fcc6c1d8e12b5
CREATE OR REPLACE FUNCTION public.v2_committee_board(p_school uuid, p_committee text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  select jsonb_build_object(
    'committee', (select jsonb_build_object('key',c.key,'label',c.label_ar,
        'purpose',c.purpose,'source',c.source_page,
        'quorum',c.quorum_min,
        'quorum_note',coalesce(c.quorum_note,
          'اجتهادُ مدرسةٍ — لا نصَّ للنصاب في الدليل التنظيميّ'))
      from v2.committees c where c.key=p_committee),
    'seats', (select jsonb_agg(jsonb_build_object(
        'ord',s.ord,'post',p.label_ar,'post_key',s.post_key,
        'role',s.seat_role,'role_ar',v2.seat_ar(s.seat_role),
        'count',s.seat_count,'elected',s.is_elected,'elected_by',s.elected_by,
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
