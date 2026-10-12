-- public.v2_loyalty_spend(p_student uuid, p_reward text, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f3e0bf73daa578b9725a305c84573d04
CREATE OR REPLACE FUNCTION public.v2_loyalty_spend(p_student uuid, p_reward text, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare
  sc uuid; me uuid; w v2.loyalty_rewards; bal int; yr uuid; tm smallint;
  new_id uuid; given int; role_label text;
begin
  me := v2.current_person();
  perform v2.assert_my_student(p_student, 'صرفَ مكافأةٍ من نقاطه');
  select school_id into sc from v2.students where id = p_student;

  w := v2.loyalty_reward(sc, p_reward);
  if w.id is null then
    raise exception 'لا مكافأةَ بالرمز «%» — أو أنّها مُغلقةٌ في لوحة التحكّم', p_reward;
  end if;

  perform v2.assert_role(w.who_may_spend, format('صرفَ «%s»', w.title_ar));

  if w.needs_principal then
    perform v2.assert_role(array['principal'], format('إذنَ صرفِ «%s»', w.title_ar));
  end if;

  if w.stock is not null then
    select count(*) into given from v2.loyalty_ledger
     where school_id = sc and reward_code = w.code and voided_at is null;
    if given >= w.stock then
      raise exception 'نفِد المتاحُ من «%» — % فقط', w.title_ar, v2.ar_num(w.stock);
    end if;
  end if;

  bal := v2.loyalty_balance(sc, p_student);
  if v2.rule_n(sc, 'loyalty_spend_needs_balance') = 1 and bal < w.price then
    raise exception 'سعرُ «%» % ورصيدُه % — فيبقى له %',
      w.title_ar, v2.ar_num(w.price), v2.ar_num(bal), v2.ar_num(w.price - bal);
  end if;

  select id into yr from v2.academic_years where school_id = sc and is_current limit 1;
  tm := v2.fn_term_of(sc, current_date);
  role_label := coalesce(v2.role_ar(v2.my_role()), 'بلا تكليف');

  insert into v2.loyalty_ledger
    (school_id, year_id, term_no, student_id, kind, reward_code, points,
     reason_ar, on_date, by_person, by_role_ar,
     approved_by)
  values
    (sc, yr, tm, p_student, 'spend', w.code, w.price,
     nullif(btrim(coalesce(p_note, '')), ''), current_date, me, role_label,
     case when w.needs_principal then me else null end)
  returning id into new_id;

  bal := v2.loyalty_balance(sc, p_student);
  return jsonb_build_object(
    'id', new_id, 'title_ar', w.title_ar, 'price', w.price, 'balance', bal,
    'said_ar', format('صُرفت «%s» بـ%s — وبقي له %s',
      w.title_ar, v2.ar_num(w.price), v2.ar_num(bal)),
    'undo_minutes', v2.rule_n(sc, 'loyalty_undo_minutes'));
end $function$
;
