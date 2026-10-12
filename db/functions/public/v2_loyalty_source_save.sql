-- public.v2_loyalty_source_save(p_code text, p_title text, p_kind text, p_points smallint, p_who text[], p_week_cap smallint, p_needs_note boolean, p_active boolean, p_ord smallint, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 cab7f88d613babe43b5c75b85acd6c2f
CREATE OR REPLACE FUNCTION public.v2_loyalty_source_save(p_code text, p_title text, p_kind text, p_points smallint, p_who text[], p_week_cap smallint DEFAULT NULL::smallint, p_needs_note boolean DEFAULT false, p_active boolean DEFAULT true, p_ord smallint DEFAULT 100, p_note text DEFAULT NULL::text)
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
                         'ضبطَ مصادر نقاط الولاء');
  if p_kind not in ('earn','deduct') then raise exception 'النوعُ كسبٌ أو خصمٌ فقط'; end if;
  if p_points is null or p_points < 1 then raise exception 'الوزنُ لا بدّ أن يكون واحدًا أو أكثر'; end if;
  if p_points > v2.rule_n(sc,'loyalty_max_per_act') then
    raise exception 'الوزنُ % يتجاوز أكبرَ ما يُقبل في الحركة (%)',
      v2.ar_num(p_points), v2.ar_num(v2.rule_n(sc,'loyalty_max_per_act'));
  end if;
  if coalesce(array_length(p_who,1),0) = 0 then
    raise exception 'لا بدّ من تعيين من يملك منحَ هذا المصدر';
  end if;

  insert into v2.loyalty_sources
    (school_id, code, title_ar, kind, points, who_may, week_cap, needs_note, active, ord, note_ar, set_by, set_at)
  values (sc, p_code, p_title, p_kind, p_points, p_who, p_week_cap, p_needs_note, p_active, p_ord, p_note, me, now())
  on conflict (school_id, code) do update
    set title_ar = excluded.title_ar, kind = excluded.kind, points = excluded.points,
        who_may = excluded.who_may, week_cap = excluded.week_cap, needs_note = excluded.needs_note,
        active = excluded.active, ord = excluded.ord, note_ar = excluded.note_ar,
        set_by = excluded.set_by, set_at = now();

  return jsonb_build_object('ok', true,
    'said_ar', format('%s مصدرُ «%s» بوزن %s',
      case when p_active then 'ثُبّت' else 'أُغلق' end, p_title, v2.ar_num(p_points)));
end $function$
;
