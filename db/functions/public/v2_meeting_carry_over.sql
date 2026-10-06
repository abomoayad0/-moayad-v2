-- public.v2_meeting_carry_over(p_meeting uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8672ce2d157a75d39dd15a9a5d45c8ff
CREATE OR REPLACE FUNCTION public.v2_meeting_carry_over(p_meeting uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare mt record; seat text; n int := 0; o smallint; it record;
begin
  select * into mt from v2.committee_meetings where id=p_meeting;
  if mt.id is null then raise exception 'الاجتماعُ غيرُ موجود'; end if;
  if mt.status in ('معتمد','ملغًى') then
    raise exception 'لا يُرحَّل إلى اجتماعٍ %', mt.status; end if;
  seat := v2.my_seat(mt.school_id,mt.committee_key);
  if seat not in ('chair','rapporteur') then
    raise exception 'ترحيلُ المتابعة للرئيس أو المقرّر'; end if;

  select coalesce(max(ord),0) into o from v2.meeting_items where meeting_id=p_meeting;
  for it in
    select i.* from v2.meeting_items i
    join v2.committee_meetings m on m.id=i.meeting_id
    where m.school_id=mt.school_id and m.committee_key=mt.committee_key
      and m.status='معتمد' and m.id <> p_meeting
      and i.outcome='أُقرّ' and i.done_at is null
      and not exists (select 1 from v2.meeting_items x
                       where x.meeting_id=p_meeting and x.carried_from=i.id)
    order by i.due_on nulls last
  loop
    o := o + 1; n := n + 1;
    insert into v2.meeting_items(meeting_id,ord,subject_kind,title_ar,
        student_id,record_id,opp_ref,carried_from)
    values (p_meeting,o,'تقرير',
        'متابعةُ قرارٍ لم يُنفَّذ: '||it.title_ar,
        it.student_id,it.record_id,it.opp_ref,it.id);
  end loop;
  return jsonb_build_object('ok',true,'carried',n,
    'note', case when n=0 then 'لا قرارَ معلَّقًا من اجتماعاتٍ سابقة'
                 else 'رُحّلت '||n||' قرارًا لم تُنفَّذ' end);
end $function$
;
