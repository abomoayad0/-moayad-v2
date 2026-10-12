-- public.v2_exit_back(p_exit uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c4fb4f81d798d53defa3aa1541ce53c3
CREATE OR REPLACE FUNCTION public.v2_exit_back(p_exit uuid, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare x record; nm text; v_min int; v_warn int; v_month int; v_mwarn int; v_days int;
begin
  select * into x from v2.class_exits where id = p_exit;
  if x.id is null then raise exception 'خروجٌ غيرُ موجود'; end if;
  if not v2.my_school(x.school_id) then raise exception 'ليست مدرستَك'; end if;
  if x.back_at is not null then raise exception 'سُجّلت عودتُه من قبل'; end if;

  update v2.class_exits
     set back_at = now(), back_by = v2.current_person(),
         back_note = nullif(btrim(coalesce(p_note,'')),'')
   where id = p_exit;

  select v2.fn_display_name(full_name) into nm from v2.students where id = x.student_id;
  v_min   := greatest(0, (extract(epoch from (now() - x.out_at))/60)::int);
  v_warn  := (v2.rule_n(x.school_id,'card_exit_minutes_warn'))::int;
  v_mwarn := (v2.rule_n(x.school_id,'card_exit_month_warn'))::int;
  v_days  := (v2.rule_n(x.school_id,'exit_window_days'))::int;
  select count(*) into v_month from v2.class_exits e
   where e.student_id = x.student_id and e.on_date >= current_date - v_days;

  return jsonb_build_object('ok',true,'minutes',v_min,
    'msg','عاد '||coalesce(nm,'الطالب')||' بعد '||v2.ar_num(v_min)||' دقيقة',
    'long', v_min > v_warn,
    'long_ar', case when v_min > v_warn
      then 'غيابُه عن الدرس أطولُ من '||v2.ar_num(v_warn)||' دقيقة — وهو حدُّ لوحة التحكّم' end,
    'month_count', v_month,
    'window_days', v_days,
    'month_ar', case when v_month > v_mwarn
      then 'خرج '||v2.ar_num(v_month)||' مرّةً في '||v2.ar_num(v_days)||' يومًا — وهو فوق حدِّ لوحة التحكّم' end);
end $function$
;
