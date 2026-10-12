-- public.v2_swap_approve(p_id uuid, p_ok boolean, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 cc88fd503a2a034d454f735f9b115c6f
CREATE OR REPLACE FUNCTION public.v2_swap_approve(p_id uuid, p_ok boolean, p_note text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare w record;
begin
  select * into w from v2.period_swaps where id=p_id;
  if w.id is null then raise exception 'لا طلبَ بهذا الرقم'; end if;
  perform v2.assert_role(array['deputy_academic','principal','deputy','deputy_school'],
                         'اعتمادَ تبديل الحصص');
  perform v2.assert_my_school(w.school_id,'اعتمادَ تبديل الحصص');
  if w.status in ('done','admin_no') then raise exception 'حُسم من قبل — ولا يُعتمد مرّتين'; end if;
  if w.status <> 'partner_ok' then raise exception 'لم يوافق الطرفُ الآخرُ بعد'; end if;

  update v2.period_swaps
     set admin_ok = p_ok, admin_at = now(), admin_by = v2.current_person(),
         admin_note = nullif(btrim(coalesce(p_note,'')),''),
         status = case when p_ok then 'done' else 'admin_no' end
   where id = p_id;

  perform v2.swap_notify(w.school_id,
    case when p_ok then 'اعتُمد تبديلُ حصّتك' else 'لم يُعتمد تبديلُ حصّتك' end,
    coalesce(nullif(btrim(coalesce(p_note,'')),''), v2.fn_to_hijri(w.on_date)||' هـ'),
    w.requester, w.on_date);
  perform v2.swap_notify(w.school_id,
    case when p_ok then 'اعتُمد التبديلُ معك' else 'لم يُعتمد التبديلُ معك' end,
    coalesce(nullif(btrim(coalesce(p_note,'')),''), v2.fn_to_hijri(w.on_date)||' هـ'),
    w.partner, w.on_date);

  return case when p_ok then 'اعتُمد التبديلُ ليوم ' || v2.fn_to_hijri(w.on_date) || ' هـ وحدَه'
              else 'لم يُعتمد' end;
end $function$
;
