-- public.v2_swap_cancel(p_id uuid, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 cb0984d5e2416854f7a924452b88ae32
CREATE OR REPLACE FUNCTION public.v2_swap_cancel(p_id uuid, p_why text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare w record; v_me uuid := v2.current_person(); v_admin boolean := true;
begin
  select * into w from v2.period_swaps where id=p_id;
  if w.id is null then raise exception 'لا طلبَ بهذا الرقم'; end if;
  perform v2.assert_my_school(w.school_id,'إلغاءَ تبديل');
  if coalesce(btrim(coalesce(p_why,'')),'') = '' then
    raise exception 'الإلغاءُ يَلزمه سببٌ مكتوب';
  end if;
  begin
    perform v2.assert_role(array['deputy_academic','principal','deputy','deputy_school'],
                           'إلغاءَ تبديل');
  exception when others then v_admin := false; end;
  if not v_admin then
    if w.requester is distinct from v_me then
      raise exception 'لا يُلغيه غيرُ صاحبه أو الإدارة'; end if;
    if w.status = 'done' then
      raise exception 'اعتُمد التبديلُ — ولا يُلغيه إلّا الإدارة'; end if;
  end if;
  if w.status in ('cancelled','partner_no','admin_no','lapsed') then
    raise exception 'ساقطٌ سلفًا'; end if;

  update v2.period_swaps set status='cancelled',
         admin_note = case when v_admin then btrim(p_why) else admin_note end,
         reason_ar = case when v_admin then reason_ar else coalesce(reason_ar,'')||' · أُلغي: '||btrim(p_why) end
   where id = p_id;
  perform v2.swap_notify(w.school_id,'أُلغي تبديلُ الحصّة', btrim(p_why), w.requester, w.on_date);
  perform v2.swap_notify(w.school_id,'أُلغي تبديلُ الحصّة', btrim(p_why), w.partner, w.on_date);
  return 'أُلغي بسببه المكتوب';
end $function$
;
