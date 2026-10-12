-- public.v2_swap_partner(p_id uuid, p_ok boolean, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c3ea01b33b0bbb2fa01f4cc7d2a9039f
CREATE OR REPLACE FUNCTION public.v2_swap_partner(p_id uuid, p_ok boolean, p_note text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare w record; v_me uuid := v2.current_person(); d record;
begin
  select * into w from v2.period_swaps where id=p_id;
  if w.id is null then raise exception 'لا طلبَ بهذا الرقم'; end if;
  perform v2.assert_my_school(w.school_id,'الجوابَ عن طلب تبديل');
  if w.partner is distinct from v_me then raise exception 'هذا الطلبُ ليس لك'; end if;
  if w.status <> 'pending' then raise exception 'حُسم من قبل'; end if;

  update v2.period_swaps
     set partner_ok = p_ok, partner_at = now(), partner_note = nullif(btrim(coalesce(p_note,'')),''),
         status = case when p_ok then 'partner_ok' else 'partner_no' end
   where id = p_id;

  perform v2.swap_notify(w.school_id,
    case when p_ok then 'وافق زميلُك على التبديل' else 'اعتذر زميلُك عن التبديل' end,
    coalesce(nullif(btrim(coalesce(p_note,'')),''),'بلا بيان'), w.requester, w.on_date);

  if p_ok then
    for d in select distinct a.person_id pid from v2.assignments a
              where a.school_id=w.school_id and a.ended_on is null
                and a.post_key in ('deputy_academic','principal')
    loop
      perform v2.swap_notify(w.school_id,'تبديلُ حصّةٍ ينتظر اعتمادَك',
        (select v2.fn_display_name(full_name) from v2.people where id=w.requester) || ' ↔ ' ||
        (select v2.fn_display_name(full_name) from v2.people where id=w.partner),
        d.pid, w.on_date);
    end loop;
  end if;

  return case when p_ok then 'وافقتَ — ينتظر اعتمادَ الوكيل للشؤون التعليميّة'
              else 'اعتذرتَ عن التبديل' end;
end $function$
;
