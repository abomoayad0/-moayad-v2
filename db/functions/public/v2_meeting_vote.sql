-- public.v2_meeting_vote(p_item uuid, p_vote text, p_note text, p_change_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b6417b11c4c881f2f948a813f2876a34
CREATE OR REPLACE FUNCTION public.v2_meeting_vote(p_item uuid, p_vote text, p_note text, p_change_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare mt record; old record;
begin
  select m.* into mt from v2.committee_meetings m
    join v2.meeting_items i on i.meeting_id=m.id where i.id=p_item;
  if mt.id is null then raise exception 'البندُ غيرُ موجود'; end if;
  if mt.status in ('معتمد','ملغًى') then
    raise exception 'لا تصويتَ في اجتماعٍ %', mt.status; end if;
  if p_vote not in ('موافق','مخالف','ممتنع') then
    raise exception 'الصوت: موافقٌ أو مخالفٌ أو ممتنع'; end if;
  if p_vote='مخالف' and btrim(coalesce(p_note,''))='' then
    raise exception 'من خالف يُثبت رأيَه في المحضر'; end if;

  select * into old from v2.meeting_votes
   where item_id=p_item and person_id=v2.current_person();

  if old.id is not null then
    if old.vote = p_vote then
      update v2.meeting_votes set note_ar=nullif(btrim(coalesce(p_note,'')),'')
       where id=old.id;
      return jsonb_build_object('ok',true,'changed',false);
    end if;
    -- 🔑 تبديلُ الصوت لا يقع بلا سببٍ مكتوب · والأوّلُ يبقى في المحضر
    if btrim(coalesce(p_change_note,''))='' then
      raise exception 'صوّتَّ «%» سلفًا — ولا يُبدَّل الصوتُ بلا سببٍ مكتوب يُثبت في المحضر', old.vote;
    end if;
    update v2.meeting_votes
       set prev_vote=old.vote, vote=p_vote,
           note_ar=nullif(btrim(coalesce(p_note,'')),''),
           change_note=btrim(p_change_note), changed_at=now(), voted_at=now()
     where id=old.id;
    return jsonb_build_object('ok',true,'changed',true,'from',old.vote,'to',p_vote);
  end if;

  insert into v2.meeting_votes(item_id,person_id,vote,note_ar)
  values (p_item,v2.current_person(),p_vote,nullif(btrim(coalesce(p_note,'')),''));
  return jsonb_build_object('ok',true,'changed',false);
end $function$
;
