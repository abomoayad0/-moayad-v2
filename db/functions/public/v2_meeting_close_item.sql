-- public.v2_meeting_close_item(p_item uuid, p_body text, p_decision text, p_recommend text, p_owner uuid, p_due date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 335bd712550bf30f24540833a39d2356
CREATE OR REPLACE FUNCTION public.v2_meeting_close_item(p_item uuid, p_body text, p_decision text, p_recommend text, p_owner uuid, p_due date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare mt record; seat text; yes int; no int; abs int; voters int; res text;
begin
  select m.* into mt from v2.committee_meetings m
    join v2.meeting_items i on i.meeting_id=m.id where i.id=p_item;
  if mt is null then raise exception 'البندُ غيرُ موجود'; end if;
  seat := v2.my_seat(mt.school_id,mt.committee_key);
  if seat is distinct from 'rapporteur' then
    raise exception 'المحضرُ يكتبه مقرّرُ اللجنة — ص١٩';
  end if;
  if btrim(coalesce(p_body,''))='' or btrim(coalesce(p_decision,''))='' then
    raise exception 'لا يُقفل بندٌ بلا مناقشةٍ وقرارٍ مكتوبين';
  end if;

  select count(*) filter (where vote='موافق'),
         count(*) filter (where vote='مخالف'),
         count(*) filter (where vote='ممتنع')
    into yes,no,abs from v2.meeting_votes where item_id=p_item;
  select count(*) into voters from v2.meeting_attendance
   where meeting_id=mt.id and state='حاضر' and can_vote;

  if (yes+no+abs) = 0 then raise exception 'لا يُقفل بندٌ بلا تصويت'; end if;
  if (yes+no+abs) < voters then
    raise exception 'لم يصوّت الأعضاءُ كلُّهم (% من %)', yes+no+abs, voters;
  end if;
  res := case when yes > no then 'أُقرّ' when no > yes then 'رُفض' else 'أُجّل' end;

  update v2.meeting_items
     set body_ar=p_body, decision_ar=p_decision,
         recommend_ar=nullif(btrim(coalesce(p_recommend,'')),''),
         owner_person=p_owner, due_on=p_due, outcome=res
   where id=p_item;
  return jsonb_build_object('ok',true,'outcome',res,'موافق',yes,'مخالف',no,'ممتنع',abs);
end $function$
;
