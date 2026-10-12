-- public.v2_practice_weight_save(p_code text, p_points numeric, p_day_cap numeric, p_active boolean, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b2f0dcc064104cf222ac25be69840c13
CREATE OR REPLACE FUNCTION public.v2_practice_weight_save(p_code text, p_points numeric, p_day_cap numeric DEFAULT NULL::numeric, p_active boolean DEFAULT true, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; me uuid; cp record; w_max numeric;
begin
  me := v2.current_person();
  sc := v2.acting_school();
  if sc is null then raise exception 'لا مدرسةَ فعّالةٌ لك الآن'; end if;
  perform v2.assert_role(array['principal','deputy','deputy_students','deputy_academic',
      'deputy_school','deputy_school_students'],'ضبطَ أوزان الممارسات');

  select * into cp from v2.class_practices where code=p_code;
  if cp.code is null then raise exception 'ممارسةٌ غيرُ معروفة: %', p_code; end if;
  if p_points is null or p_points < 0 then raise exception 'الوزنُ صفرٌ أو أكثر'; end if;
  w_max := (v2.rule_n(sc,'practice_weight_max_pct'))::numeric / 100;
  if p_points > w_max then
    raise exception 'الوزنُ % يتجاوز أكبرَ ما يُقبل في الحركة الواحدة (%)',
      v2.ar_num(p_points), v2.ar_num(w_max);
  end if;

  insert into v2.practice_weights (school_id,code,points,day_cap,active,note_ar,set_by,set_at)
  values (sc,p_code,p_points,p_day_cap,p_active,nullif(btrim(coalesce(p_note,'')),''),me,now())
  on conflict (school_id,code) do update
    set points=excluded.points, day_cap=excluded.day_cap, active=excluded.active,
        note_ar=excluded.note_ar, set_by=excluded.set_by, set_at=now();

  return jsonb_build_object('ok',true,'code',p_code,'points',p_points,
    'said_ar', format('%s وزنُ «%s» عند %s%s',
      case when p_active then 'ثُبّت' else 'أُوقف' end, cp.title_ar, v2.ar_num(p_points),
      case when cp.polarity='negative' and v2.rule_n(sc,'practice_negative_weighed') <> 1
           then ' — ولن يُحسم حتى يُفتح مفتاحُ «السالبُ يمسُّ الرصيد» في لوحة التحكّم' else '' end));
end $function$
;
