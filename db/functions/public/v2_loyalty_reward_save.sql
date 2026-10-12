-- public.v2_loyalty_reward_save(p_code text, p_title text, p_price smallint, p_who text[], p_needs_principal boolean, p_stock smallint, p_active boolean, p_ord smallint, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a62155c8c90c58c76d7715a4cc3f2d61
CREATE OR REPLACE FUNCTION public.v2_loyalty_reward_save(p_code text, p_title text, p_price smallint, p_who text[], p_needs_principal boolean DEFAULT false, p_stock smallint DEFAULT NULL::smallint, p_active boolean DEFAULT true, p_ord smallint DEFAULT 100, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; me uuid;
begin
  me := v2.current_person();
  sc := v2.acting_school();
  if sc is null then raise exception 'لا مدرسةَ فعّالةٌ لك الآن'; end if;
  perform v2.assert_role(array['principal','deputy','deputy_students','deputy_academic',
                               'deputy_school','deputy_school_students'],
                         'ضبطَ مكافآت نقاط الولاء');
  if p_price is null or p_price < 1 then raise exception 'السعرُ لا بدّ أن يكون واحدًا أو أكثر'; end if;
  if coalesce(array_length(p_who,1),0) = 0 then
    raise exception 'لا بدّ من تعيين من يملك صرفَ هذه المكافأة';
  end if;

  insert into v2.loyalty_rewards
    (school_id, code, title_ar, price, who_may_spend, needs_principal, stock, active, ord, note_ar, set_by, set_at)
  values (sc, p_code, p_title, p_price, p_who, p_needs_principal, p_stock, p_active, p_ord, p_note, me, now())
  on conflict (school_id, code) do update
    set title_ar = excluded.title_ar, price = excluded.price, who_may_spend = excluded.who_may_spend,
        needs_principal = excluded.needs_principal, stock = excluded.stock, active = excluded.active,
        ord = excluded.ord, note_ar = excluded.note_ar, set_by = excluded.set_by, set_at = now();

  return jsonb_build_object('ok', true,
    'said_ar', format('%s مكافأةُ «%s» بسعر %s',
      case when p_active then 'ثُبّتت' else 'أُغلقت' end, p_title, v2.ar_num(p_price)));
end $function$
;
