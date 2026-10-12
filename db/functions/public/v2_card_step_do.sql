-- public.v2_card_step_do(p_step uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7fca1a544b5fe674bf7fc861f046a900
CREATE OR REPLACE FUNCTION public.v2_card_step_do(p_step uuid, p_note text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare s record; me uuid := v2.current_person(); v_min int;
begin
  select * into s from v2.card_due_steps where id=p_step;
  if s.id is null then raise exception 'لا خطوةَ بهذا المعرّف'; end if;
  perform v2.assert_my_school(s.school_id,'إنجازَ خطوةٍ مستحقّة');
  if s.answered_at is not null then raise exception 'أُجيبت سلفًا'; end if;
  if s.owner_person <> me and v2.my_role() not in ('principal','deputy','deputy_students') then
    raise exception 'هذي الخطوةُ من عملِ غيرك — ولستَ منهم'; end if;
  v_min := v2.rule_n(s.school_id,'reason_min_chars');
  if length(btrim(coalesce(p_note,''))) < v_min then
    raise exception 'اكتب ما فعلتَ — وأقلُّه % حرفًا', v2.ar_num(v_min); end if;

  update v2.card_due_steps set answered_at=now(), answered_by=me, answer_note=btrim(p_note)
   where id=p_step;

  return jsonb_build_object('ok',true,'step',p_step,
    'summary_ar','أُثبت ما فعلتَ — «'||s.title_ar||'»');
end $function$
;
