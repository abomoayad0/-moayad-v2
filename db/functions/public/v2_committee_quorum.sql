-- public.v2_committee_quorum(p_school uuid, p_committee text, p_min smallint, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 01e580ce4007a157e73b4d02a5bef9bd
CREATE OR REPLACE FUNCTION public.v2_committee_quorum(p_school uuid, p_committee text, p_min smallint, p_note text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare c record; seats int;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy'],'ضبط نصاب اللجان');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select * into c from v2.committees where key=p_committee;
  if c.key is null then raise exception 'لجنةٌ غيرُ معروفة'; end if;
  if p_min is null then
    delete from v2.committee_school_rules
     where school_id=p_school and committee_key=p_committee and seat_role='';
    return jsonb_build_object('ok',true,'quorum',null); end if;
  if p_min < 2 then raise exception 'لا ينعقد اجتماعٌ بأقلَّ من عضوين'; end if;
  select coalesce(sum(case when s.post_key is null
            then v2.seat_cap(p_school,p_committee,s.seat_role) else s.seat_count end),0)
    into seats from v2.committee_seats s where s.committee_key=p_committee;
  if p_min > seats then
    raise exception 'النصابُ (%) أكبرُ من مقاعد اللجنة في هذي المدرسة (%)', p_min, seats; end if;
  if btrim(coalesce(p_note,''))='' then
    raise exception 'لا يُضبط نصابٌ بلا سببٍ مكتوب — فلا نصَّ له في الدليل'; end if;

  insert into v2.committee_school_rules(school_id,committee_key,seat_role,quorum_min,reason_ar,set_by)
  values (p_school,p_committee,'',p_min,
    'اجتهادُ مدرسةٍ — لا نصَّ للنصاب في الدليل التنظيميّ · '||btrim(p_note), v2.current_person())
  on conflict (school_id,committee_key,seat_role) do update
    set quorum_min=excluded.quorum_min, reason_ar=excluded.reason_ar,
        set_by=excluded.set_by, set_at=now();
  return jsonb_build_object('ok',true,'quorum',p_min,'seats',seats);
end $function$
;
