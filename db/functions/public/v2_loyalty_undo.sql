-- public.v2_loyalty_undo(p_id uuid, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5460fdda7e4869da561f9fc277438455
CREATE OR REPLACE FUNCTION public.v2_loyalty_undo(p_id uuid, p_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare g v2.loyalty_ledger; me uuid; mins int; age_min numeric; bal int;
begin
  me := v2.current_person();
  select * into g from v2.loyalty_ledger where id = p_id;
  if g.id is null then raise exception 'لا حركةَ بهذا المُعرّف'; end if;
  perform v2.assert_my_school(g.school_id, 'سحبَ حركةِ نقاط');
  if g.voided_at is not null then
    raise exception 'هذه الحركةُ مسحوبةٌ من قبل — %', coalesce(g.void_reason, 'بلا سبب');
  end if;

  mins    := v2.rule_n(g.school_id, 'loyalty_undo_minutes');
  age_min := extract(epoch from (now() - g.created_at)) / 60;

  if g.by_person = me and age_min <= mins then
    null;                                   -- صاحبُها في مهلتها
  else
    perform v2.assert_role(
      array['principal','deputy','deputy_students','deputy_school','deputy_school_students','counselor'],
      format('سحبَ حركةٍ مضى عليها %s دقيقة', v2.ar_num(floor(age_min))));
  end if;

  if g.kind = 'deduct' and coalesce(btrim(coalesce(p_reason, '')), '') = '' then
    raise exception 'سحبُ الخصم يلزمه سببٌ مكتوب';
  end if;

  update v2.loyalty_ledger
     set voided_at = now(), voided_by = me,
         void_reason = coalesce(nullif(btrim(coalesce(p_reason, '')), ''), 'سُحبت في مهلتها')
   where id = p_id;

  bal := v2.loyalty_balance(g.school_id, g.student_id);
  return jsonb_build_object(
    'ok', true, 'balance', bal,
    'said_ar', format('سُحبت الحركةُ (%s · %s) — ورصيدُه الآن %s',
      case g.kind when 'earn' then 'كسب' when 'deduct' then 'خصم' else 'صرف' end,
      v2.ar_num(g.points), v2.ar_num(bal)));
end $function$
;
