-- public.v2_meeting_close_item(p_item uuid, p_body text, p_decision text, p_recommend text, p_owner uuid, p_due date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 047c41e1566fcd351b4e0537f40a0772
CREATE OR REPLACE FUNCTION public.v2_meeting_close_item(p_item uuid, p_body text, p_decision text, p_recommend text, p_owner uuid, p_due date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare mt record; it record; seat text; yes int; no int; abst int; repl int; res text;
        rule jsonb; chair uuid; chair_vote text; cast_used boolean := false;
begin
  select i.* into it from v2.meeting_items i where i.id=p_item;
  if it.id is null then raise exception 'البندُ غيرُ موجود'; end if;
  select * into mt from v2.committee_meetings where id=it.meeting_id;

  -- 🔑 حارسُ الحال
  if mt.status in ('معتمد','ملغًى') then
    raise exception 'لا يُعدَّل بندٌ في محضرٍ % — وإن لزم فاجتماعٌ جديدٌ يشير إليه', mt.status; end if;
  if mt.status = 'موثّق' then
    raise exception 'وُثّق المحضرُ — فلا يُقفل بندٌ بعده. أعده إلى «منعقد» إن لزم'; end if;
  if it.outcome <> 'قيد النظر' then
    raise exception 'قُفل هذا البندُ سلفًا (%)', it.outcome; end if;

  seat := v2.my_seat(mt.school_id,mt.committee_key);
  if seat is distinct from 'rapporteur' then
    raise exception '%', 'المحضرُ يكتبه مقرّرُ اللجنة — '||v2.cite_page('committee.meetings')||''; end if;
  if btrim(coalesce(p_body,''))='' or btrim(coalesce(p_decision,''))='' then
    raise exception 'لا يُقفل بندٌ بلا مناقشةٍ وقرارٍ مكتوبين'; end if;

  select count(*) filter (where vote='موافق'),
         count(*) filter (where vote='مخالف'),
         count(*) filter (where vote='ممتنع')
    into yes,no,abst from v2.meeting_votes where item_id=p_item;
  select count(*) into repl from v2.meeting_attendance
   where meeting_id=mt.id and state in ('حاضر','عن بُعد') and can_vote;

  if (yes+no+abst) = 0 then raise exception 'لا يُقفل بندٌ بلا تصويت'; end if;
  if (yes+no+abst) < repl then
    raise exception 'لم يردّ الأعضاءُ كلُّهم (% من %) — ومن غاب أو اعتذر لا يُنتظر',
      yes+no+abst, repl; end if;

  rule := v2.committee_rule(mt.school_id, mt.committee_key);
  if yes > no then res := 'أُقرّ';
  elsif no > yes then res := 'رُفض';
  else
    if (rule->>'tie_rule') = 'رئيس' then
      select person_id into chair from v2.committee_members
       where committee_key=mt.committee_key and school_id=mt.school_id
         and seat_role='chair' and ended_on is null limit 1;
      select vote into chair_vote from v2.meeting_votes
       where item_id=p_item and person_id=chair;
      if chair_vote = 'موافق' then res := 'أُقرّ'; cast_used := true;
      elsif chair_vote = 'مخالف' then res := 'رُفض'; cast_used := true;
      else res := 'أُجّل'; end if;
    else res := 'أُجّل'; end if;
  end if;

  -- 🔑 والقرارُ المُقرُّ يلزمه منفِّذٌ وموعدٌ هنا لا عند الاعتماد
  if res = 'أُقرّ' then
    if p_owner is null then raise exception 'اختر من ينفّذ القرار'; end if;
    if p_due is null then raise exception 'اكتب موعدَ التنفيذ'; end if;
    if p_due < current_date then raise exception 'موعدُ التنفيذ مضى'; end if;
  end if;

  update v2.meeting_items
     set body_ar=p_body,
         decision_ar = p_decision ||
           case when cast_used then
             ' · تعادلت الأصواتُ فرُجّح جانبُ رئيس اللجنة ('||chair_vote||
             ') — اجتهادُ مدرسةٍ لا نصَّ له في الدليل' else '' end,
         recommend_ar=nullif(btrim(coalesce(p_recommend,'')),''),
         owner_person=p_owner, due_on=p_due, outcome=res
   where id=p_item;
  return jsonb_build_object('ok',true,'outcome',res,'موافق',yes,'مخالف',no,'ممتنع',abst,
    'ردّوا',repl,'رجّح_الرئيس',cast_used);
end $function$
;
